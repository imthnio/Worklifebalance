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
    private var finishTime: Date!
    private var pausedTimeLeft: TimeInterval = 0
    private var totalTime: TimeInterval = 1
    private var timerFormatter = DateComponentsFormatter()
    @Published private(set) var state: TBState = .idle
    @Published var timeLeftString: String = ""
    /// Fraction of the current round still remaining, from 1 down to 0
    @Published private(set) var progress: Double = 1
    @Published var timer: DispatchSourceTimer?

    init() {
        timerFormatter.unitsStyle = .positional
        timerFormatter.allowedUnits = [.minute, .second]
        timerFormatter.zeroFormattingBehavior = .pad

        let hotKeys = HotKeyCenter.shared
        hotKeys.onPress(.startStop) { [unowned self] in startStop() }
        hotKeys.onPress(.pauseResume) { [unowned self] in pauseResume() }
        hotKeys.onPress(.reset) { [unowned self] in reset() }
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
        switch state {
        case .idle:
            startWork(seconds: workIntervalLength * 60)
        case .work, .paused:
            stop()
        }
    }

    func pauseResume() {
        switch state {
        case .idle:
            return
        case .work:
            pausedTimeLeft = max(finishTime.timeIntervalSince(Date()), 0)
            cancelTimer()
            state = .paused
            TBStatusItem.shared.setIcon(name: .idle)
            updateTimeLeft()
        case .paused:
            startWork(seconds: Int(pausedTimeLeft.rounded()))
        }
    }

    /// Restarts the current round from the beginning
    func reset() {
        guard state != .idle else { return }
        cancelTimer()
        state = .idle
        startWork(seconds: workIntervalLength * 60)
    }

    func updateTimeLeft() {
        switch state {
        case .idle:
            progress = 1
            TBStatusItem.shared.setTitle(title: nil)
            return
        case .paused:
            timeLeftString = format(seconds: pausedTimeLeft)
            progress = pausedTimeLeft / totalTime
        case .work:
            let timeLeft = max(finishTime.timeIntervalSince(Date()), 0)
            timeLeftString = format(seconds: timeLeft)
            progress = timeLeft / totalTime
        }
        TBStatusItem.shared.setTitle(title: showTimerInMenuBar ? timeLeftString : nil)
    }

    func format(seconds: TimeInterval) -> String {
        timerFormatter.string(from: seconds.rounded(.up))!
    }

    private func startWork(seconds: Int) {
        if state != .paused {
            totalTime = TimeInterval(seconds)
        }
        state = .work
        TBStatusItem.shared.setIcon(name: .work)
        startTimer(seconds: seconds)
    }

    private func stop() {
        cancelTimer()
        state = .idle
        TBStatusItem.shared.setIcon(name: .idle)
        updateTimeLeft()
    }

    private func finish() {
        cancelTimer()
        player.playAlert()
        let l10n = L10n.shared
        if autoRestart {
            startWork(seconds: workIntervalLength * 60)
        } else {
            state = .idle
            TBStatusItem.shared.setIcon(name: .idle)
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

    private func startTimer(seconds: Int) {
        finishTime = Date().addingTimeInterval(TimeInterval(seconds))

        let queue = DispatchQueue(label: "Timer")
        timer = DispatchSource.makeTimerSource(flags: .strict, queue: queue)
        timer!.schedule(deadline: .now(), repeating: .seconds(1), leeway: .never)
        timer!.setEventHandler(handler: onTimerTick)
        timer!.resume()
    }

    private func cancelTimer() {
        timer?.cancel()
        timer = nil
    }

    private func onTimerTick() {
        /* Cannot publish updates from background thread */
        DispatchQueue.main.async { [self] in
            guard state == .work else { return }
            updateTimeLeft()
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
            }
        }
    }
}
