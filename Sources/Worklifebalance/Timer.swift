import SwiftUI

enum TBState {
    case idle, work, paused
}

class TBTimer: ObservableObject {
    @AppStorage("autoRestart") var autoRestart = false
    @AppStorage("showTimerInMenuBar") var showTimerInMenuBar = true
    @AppStorage("workIntervalLength") var workIntervalLength = 25
    // This preference is "hidden"
    @AppStorage("overrunTimeLimit") var overrunTimeLimit = -60.0

    public let player = TBPlayer()
    private var finishTime: Date?
    private var pausedTimeLeft: TimeInterval = 0
    private var totalTime: TimeInterval = 1
    private var timerFormatter = DateComponentsFormatter()
    @Published private(set) var state: TBState = .idle
    @Published var timeLeftString: String = ""
    /// Fraction of the current round still remaining, from 1 down to 0
    @Published private(set) var progress: Double = 1
    private var timer: DispatchSourceTimer?

    private var clampedWorkSeconds: TimeInterval {
        TimeInterval(min(max(workIntervalLength, 1), 120) * 60)
    }

    init() {
        timerFormatter.unitsStyle = .positional
        timerFormatter.allowedUnits = [.minute, .second]
        timerFormatter.zeroFormattingBehavior = .pad

        let hotKeys = HotKeyCenter.shared
        hotKeys.onPress(.startStop) { [weak self] in self?.startStop() }
        hotKeys.onPress(.pauseResume) { [weak self] in self?.pauseResume() }
        hotKeys.onPress(.reset) { [weak self] in self?.reset() }
        hotKeys.onPress(.togglePopover) { TBStatusItem.shared.togglePopover(nil) }
        hotKeys.onPress(.quit) { NSApp.terminate(nil) }

        let aem: NSAppleEventManager = NSAppleEventManager.shared()
        aem.setEventHandler(self,
                            andSelector: #selector(handleGetURLEvent(_:withReplyEvent:)),
                            forEventClass: AEEventClass(kInternetEventClass),
                            andEventID: AEEventID(kAEGetURL))
    }

    @objc func handleGetURLEvent(_ event: NSAppleEventDescriptor,
                                 withReplyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.forKeyword(AEKeyword(keyDirectObject))?.stringValue,
              let url = URL(string: urlString),
              let scheme = url.scheme,
              let host = url.host,
              scheme.caseInsensitiveCompare("worklifebalance") == .orderedSame
        else {
            print("url handling error: cannot parse url")
            return
        }
        switch host.lowercased() {
        case "startstop":
            startStop()
        case "pauseresume":
            pauseResume()
        case "reset":
            reset()
        default:
            print("url handling error: unknown command \(host)")
        }
    }

    func startStop() {
        // Starting or stopping by hand means the last reminder has been seen
        TBBanner.shared.hide()
        switch state {
        case .idle:
            startWork(seconds: clampedWorkSeconds)
        case .work, .paused:
            stop()
        }
    }

    func pauseResume() {
        switch state {
        case .idle:
            return
        case .work:
            pausedTimeLeft = max(finishTime?.timeIntervalSince(Date()) ?? 0, 0)
            TBStats.shared.end()
            cancelTimer()
            finishTime = nil
            state = .paused
            TBStatusItem.shared.setIcon(working: false)
            updateTimeLeft()
        case .paused:
            if pausedTimeLeft <= 0 {
                finish()
            } else {
                startWork(seconds: pausedTimeLeft)
            }
        }
    }

    /// Restarts the current round from the beginning
    func reset() {
        guard state != .idle else { return }
        TBBanner.shared.hide()
        TBStats.shared.end()
        cancelTimer()
        state = .idle
        startWork(seconds: clampedWorkSeconds)
    }

    /// Sets a new focus length; a round in progress starts over with it (a paused one stays paused)
    func setWorkLength(minutes: Int) {
        workIntervalLength = min(max(minutes, 1), 120)
        switch state {
        case .idle:
            objectWillChange.send()
        case .work:
            reset()
        case .paused:
            pausedTimeLeft = clampedWorkSeconds
            totalTime = pausedTimeLeft
            updateTimeLeft()
        }
    }

    func updateTimeLeft() {
        switch state {
        case .idle:
            progress = 1
            TBStatusItem.shared.setTitle(title: nil)
            return
        case .paused:
            timeLeftString = format(seconds: pausedTimeLeft)
            progress = min(max(pausedTimeLeft / max(totalTime, 1), 0), 1)
        case .work:
            let timeLeft = max(finishTime?.timeIntervalSince(Date()) ?? 0, 0)
            timeLeftString = format(seconds: timeLeft)
            progress = min(max(timeLeft / max(totalTime, 1), 0), 1)
        }
        TBStatusItem.shared.setTitle(title: showTimerInMenuBar ? timeLeftString : nil)
    }

    /// When the running round will end
    var endTime: Date? {
        state == .work ? finishTime : nil
    }

    func format(seconds: TimeInterval) -> String {
        timerFormatter.string(from: max(seconds, 0).rounded(.up)) ?? "00:00"
    }

    private func startWork(seconds: TimeInterval) {
        if state != .paused {
            totalTime = max(seconds, 1)
        }
        finishTime = Date().addingTimeInterval(seconds)
        state = .work
        TBStatusItem.shared.setIcon(working: true)
        TBStats.shared.begin()
        updateTimeLeft()
        startTimer(seconds: seconds)
    }

    private func stop() {
        TBStats.shared.end()
        cancelTimer()
        finishTime = nil
        state = .idle
        TBStatusItem.shared.setIcon(working: false)
        updateTimeLeft()
    }

    private func finish() {
        TBStats.shared.end()
        cancelTimer()
        finishTime = nil
        player.playAlert()
        let l10n = L10n.shared
        if autoRestart {
            startWork(seconds: clampedWorkSeconds)
        } else {
            state = .idle
            TBStatusItem.shared.setIcon(working: false)
            updateTimeLeft()
        }
        TBBanner.shared.show(
            title: l10n.t("notify.finished.title"),
            body: l10n.t("notify.finished.body"),
            startNext: autoRestart ? nil : { [weak self] in
                guard let self = self, self.state == .idle else { return }
                self.startStop()
            }
        )
    }

    private func startTimer(seconds: TimeInterval) {
        cancelTimer()
        let source = DispatchSource.makeTimerSource(flags: .strict, queue: .main)
        let remainder = seconds.truncatingRemainder(dividingBy: 1)
        let firstDelay = (remainder > 0.05 ? remainder : min(seconds, 1.0)) + 0.01
        source.schedule(deadline: .now() + firstDelay, repeating: .seconds(1), leeway: .milliseconds(10))
        source.setEventHandler { [weak self] in
            self?.onTimerTick()
        }
        timer = source
        source.resume()
    }

    private func cancelTimer() {
        timer?.cancel()
        timer = nil
    }

    private func onTimerTick() {
        guard state == .work, let finishTime = finishTime else { return }
        let timeLeft = finishTime.timeIntervalSince(Date())
        if timeLeft <= 0 {
            /*
             Ticks can be missed during the machine sleep.
             Stop the timer if it goes beyond an overrun time limit.
             */
            if timeLeft < overrunTimeLimit {
                stop()
            } else {
                finish()
            }
            return
        }
        TBStats.shared.mark()
        updateTimeLeft()
    }
}
