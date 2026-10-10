import SwiftUI

// MARK: - Styling

let tomato = Color(red: 0.96, green: 0.33, blue: 0.27)
private let startGreen = Color(red: 0.20, green: 0.78, blue: 0.35)
private let pauseOrange = Color(red: 1.0, green: 0.62, blue: 0.04)

private struct CircleButtonStyle: ButtonStyle {
    let tint: Color?

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(tint ?? .primary)
            .circleBackground(tint: tint)
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

private extension View {
    /// Liquid Glass on macOS 26+, a matching translucent fill before that.
    /// Tinted buttons follow the Clock app: colored label on a soft tinted circle.
    @ViewBuilder
    func circleBackground(tint: Color?) -> some View {
        if #available(macOS 26, *) {
            self.glassEffect(tint.map { .regular.tint($0.opacity(0.3)).interactive() }
                             ?? .regular.interactive(),
                             in: Circle())
        } else {
            self.background(Circle().fill((tint ?? .primary).opacity(tint == nil ? 0.08 : 0.2)))
        }
    }

    @ViewBuilder
    func countdownTransition() -> some View {
        if #available(macOS 14, *) {
            self.contentTransition(.numericText(countsDown: true))
        } else {
            self
        }
    }
}

private class HoverState: ObservableObject {
    @Published var hovered = false
}

/// A menu-like row that highlights on hover, as in the system's menu bar extras
private struct MenuRow: View {
    let title: String
    var shortcut: String = ""
    let action: () -> Void
    @StateObject private var hover = HoverState()

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
                Text(shortcut).foregroundColor(.secondary)
            }
            .font(.system(size: 13))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(hover.hovered ? Color.primary.opacity(0.1) : .clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hover.hovered = $0 }
    }
}

// MARK: - Settings building blocks

/// A titled, rounded group of rows in the style of System Settings
private struct SettingsSection<Content: View>: View {
    let title: String
    var footer: String?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.leading, 4)
            VStack(spacing: 0) {
                content
            }
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.primary.opacity(0.05))
            )
            if let footer = footer {
                Text(footer)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 4)
            }
        }
    }
}

private struct SettingsRow<Trailing: View>: View {
    let title: String
    var divider = true
    @ViewBuilder let trailing: Trailing

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Text(title)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                trailing
            }
            .frame(minHeight: 22)
            .padding(.vertical, 6)
            if divider {
                Divider()
            }
        }
    }
}

private struct VolumeSlider: View {
    @Binding var volume: Double

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "speaker.fill").foregroundColor(.secondary)
            Slider(value: $volume, in: 0...2)
                .gesture(TapGesture(count: 2).onEnded({
                    volume = 1.0
                }))
            Image(systemName: "speaker.wave.3.fill").foregroundColor(.secondary)
        }
        .font(.system(size: 9))
    }
}

// MARK: - Settings page

private struct SettingsPage: View {
    @ObservedObject var timer: TBTimer
    @ObservedObject var player: TBPlayer
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var launchAtLogin = LaunchAtLogin.shared

    private let workLengthRange = 1 ... 120

    /// Typed values are clamped to the allowed range
    private var workLength: Binding<Int> {
        Binding(
            get: { timer.workIntervalLength },
            set: { timer.workIntervalLength = min(max($0, workLengthRange.lowerBound),
                                                  workLengthRange.upperBound) }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            timerSection
            alertSection
            shortcutsSection
            generalSection
        }
        .font(.system(size: 13))
        .controlSize(.small)
    }

    private var timerSection: some View {
        SettingsSection(title: l10n.t("tab.timer")) {
            SettingsRow(title: l10n.t("timer.workLength")) {
                TextField("", value: workLength, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 44)
                Text(l10n.t("timer.minUnit")).foregroundColor(.secondary)
                Stepper("", value: $timer.workIntervalLength, in: workLengthRange)
                    .labelsHidden()
            }
            SettingsRow(title: l10n.t("timer.autoRestart"), divider: false) {
                Toggle("", isOn: $timer.autoRestart)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }
        }
    }

    private var alertSection: some View {
        let hasFile = !player.customAlertSoundPath.isEmpty
        return SettingsSection(title: l10n.t("sounds.alertFile"),
                               footer: player.customAlertSoundUnavailable
                                   ? l10n.t("sounds.missing") : nil) {
            SettingsRow(title: hasFile
                            ? URL(fileURLWithPath: player.customAlertSoundPath).lastPathComponent
                            : l10n.t("sounds.none"),
                        divider: hasFile) {
                if hasFile {
                    Button {
                        player.playAlert()
                    } label: {
                        Image(systemName: "play.fill")
                    }
                    .help(l10n.t("sounds.preview"))
                    Button {
                        player.customAlertSoundPath = ""
                    } label: {
                        Image(systemName: "trash")
                    }
                    .help(l10n.t("sounds.remove"))
                }
                Button(l10n.t("sounds.choose")) {
                    player.chooseCustomAlertSound()
                }
            }
            .foregroundColor(player.customAlertSoundUnavailable ? .red : .primary)
            .help(player.customAlertSoundPath)
            if hasFile {
                SettingsRow(title: l10n.t("sounds.volume"), divider: false) {
                    VolumeSlider(volume: $player.customAlertVolume)
                        .frame(width: 130)
                }
            }
        }
    }

    private var shortcutsSection: some View {
        SettingsSection(title: l10n.t("tab.shortcuts"), footer: l10n.t("shortcut.hint")) {
            ForEach(HotKeyAction.allCases) { action in
                SettingsRow(title: l10n.t(action.titleKey)) {
                    HotKeyRecorder(action: action)
                }
            }
            HStack {
                Spacer()
                Button(l10n.t("shortcut.restoreDefaults")) {
                    HotKeyCenter.shared.restoreDefaults()
                }
            }
            .padding(.vertical, 6)
        }
    }

    private var generalSection: some View {
        SettingsSection(title: l10n.t("settings.general")) {
            SettingsRow(title: l10n.t("settings.language")) {
                Picker("", selection: $l10n.language) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(lang.nativeName).tag(lang)
                    }
                }
                .labelsHidden()
                .fixedSize()
            }
            SettingsRow(title: l10n.t("settings.showTimer")) {
                Toggle("", isOn: $timer.showTimerInMenuBar)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .onChange(of: timer.showTimerInMenuBar) { _ in
                        timer.updateTimeLeft()
                    }
            }
            SettingsRow(title: l10n.t("settings.launchAtLogin"), divider: false) {
                Toggle("", isOn: $launchAtLogin.isEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }
        }
    }
}

// MARK: - Timer page

private struct ProgressRing: View {
    let progress: Double
    let active: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: 7)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(pauseOrange, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .opacity(active ? 1 : 0.4)
        }
        .animation(.linear(duration: 1), value: progress)
        .animation(.easeInOut(duration: 0.3), value: active)
    }
}

private struct CircleButton: View {
    let title: String
    var tint: Color?
    var size: CGFloat = 64
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 4)
                .frame(width: size, height: size)
                .contentShape(Circle())
        }
        .buttonStyle(CircleButtonStyle(tint: tint))
    }
}

/// Number field for the focus length: type digits, ↑/↓ or scroll to adjust, Return to confirm, Esc to cancel
private final class MinutesTextField: NSTextField {
    var onStep: ((Int) -> Void)?
    private var scrollAccumulator: CGFloat = 0

    override func scrollWheel(with event: NSEvent) {
        var delta = event.scrollingDeltaY
        if event.isDirectionInvertedFromDevice { delta = -delta }
        // Trackpads send many small deltas; mouse wheels send whole lines
        let threshold: CGFloat = event.hasPreciseScrollingDeltas ? 8 : 1
        scrollAccumulator += delta
        while abs(scrollAccumulator) >= threshold {
            onStep?(scrollAccumulator > 0 ? 1 : -1)
            scrollAccumulator -= scrollAccumulator > 0 ? threshold : -threshold
        }
    }
}

private struct MinutesField: NSViewRepresentable {
    @Binding var value: Int
    let onCommit: () -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> MinutesTextField {
        let field = MinutesTextField()
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.alignment = .center
        field.font = .monospacedDigitSystemFont(ofSize: 44, weight: .light)
        field.stringValue = "\(value)"
        field.delegate = context.coordinator
        field.onStep = { context.coordinator.step($0) }
        context.coordinator.field = field
        DispatchQueue.main.async {
            field.window?.makeFirstResponder(field)
            field.currentEditor()?.selectAll(nil)
        }
        return field
    }

    func updateNSView(_ field: MinutesTextField, context: Context) {
        context.coordinator.parent = self
        if Int(field.stringValue) != value, !(field.stringValue.isEmpty && value == 0) {
            field.stringValue = "\(value)"
        }
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: MinutesField
        weak var field: NSTextField?
        private var finished = false

        init(_ parent: MinutesField) { self.parent = parent }

        func step(_ delta: Int) {
            let next = min(max(parent.value + delta, 1), 120)
            parent.value = next
            field?.stringValue = "\(next)"
            field?.currentEditor()?.selectAll(nil)
        }

        func controlTextDidChange(_ note: Notification) {
            guard let field = field else { return }
            let digits = String(field.stringValue.filter(\.isNumber).prefix(3))
            if digits != field.stringValue { field.stringValue = digits }
            parent.value = Int(digits) ?? 0
        }

        func control(_: NSControl, textView _: NSTextView, doCommandBy selector: Selector) -> Bool {
            switch selector {
            case #selector(NSResponder.insertNewline(_:)):
                finish(commit: true)
            case #selector(NSResponder.cancelOperation(_:)):
                finish(commit: false)
            case #selector(NSResponder.moveUp(_:)):
                step(1)
            case #selector(NSResponder.moveDown(_:)):
                step(-1)
            default:
                return false
            }
            return true
        }

        func controlTextDidEndEditing(_: Notification) {
            finish(commit: true)
        }

        private func finish(commit: Bool) {
            guard !finished else { return }
            finished = true
            commit ? parent.onCommit() : parent.onCancel()
        }
    }
}

private class TimeEditState: ObservableObject {
    @Published var editing = false
    @Published var minutes = 25
}

private struct TimerPage: View {
    @ObservedObject var timer: TBTimer
    @ObservedObject private var l10n = L10n.shared
    @StateObject private var edit = TimeEditState()

    private var displayTime: String {
        timer.state == .idle
            ? timer.format(seconds: TimeInterval(timer.workIntervalLength * 60))
            : timer.timeLeftString
    }

    var body: some View {
        VStack(spacing: 18) {
            clock
            controls
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: timer.state)
        .onReceive(NotificationCenter.default.publisher(for: .tbPopoverDidClose)) { _ in
            if edit.editing { commitEdit() }
        }
    }

    private func beginEdit() {
        edit.minutes = timer.workIntervalLength
        withAnimation(.easeOut(duration: 0.15)) { edit.editing = true }
    }

    private func commitEdit() {
        guard edit.editing else { return }
        if edit.minutes > 0, edit.minutes != timer.workIntervalLength || timer.state != .idle {
            timer.setWorkLength(minutes: edit.minutes)
        }
        withAnimation(.easeOut(duration: 0.15)) { edit.editing = false }
    }

    private func cancelEdit() {
        withAnimation(.easeOut(duration: 0.15)) { edit.editing = false }
    }

    private var clock: some View {
        ZStack {
            ProgressRing(progress: timer.progress, active: timer.state == .work)
            if edit.editing {
                editor
            } else {
                VStack(spacing: 4) {
                    Text(displayTime)
                        .font(.system(size: 44, weight: .light))
                        .monospacedDigit()
                        .countdownTransition()
                        .animation(.spring(response: 0.3, dampingFraction: 0.9), value: displayTime)
                        .opacity(timer.state == .paused ? 0.45 : 1)
                        .animation(timer.state == .paused
                                   ? .easeInOut(duration: 0.9).repeatForever()
                                   : .default,
                                   value: timer.state == .paused)
                        .contentShape(Rectangle())
                        .onTapGesture(count: 2, perform: beginEdit)
                        .help(l10n.t("timer.editHint"))
                    subtitle
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: 196, height: 196)
    }

    private var editor: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                MinutesField(value: $edit.minutes, onCommit: commitEdit, onCancel: cancelEdit)
                    .frame(width: 92, height: 54)
                VStack(spacing: 2) {
                    stepButton("chevron.up", 1)
                    stepButton("chevron.down", -1)
                }
            }
            .padding(.leading, 22)
            Text(l10n.t("timer.minUnit"))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            Text(l10n.t("timer.editKeys"))
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(width: 150)
        }
        .transition(.opacity)
    }

    private func stepButton(_ symbol: String, _ delta: Int) -> some View {
        Button {
            edit.minutes = min(max(edit.minutes + delta, 1), 120)
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .frame(width: 18, height: 16)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundColor(.secondary)
    }

    @ViewBuilder
    private var subtitle: some View {
        switch timer.state {
        case .idle:
            Text(l10n.t("status.ready"))
        case .work:
            if let end = timer.endTime {
                Label {
                    Text(end, style: .time)
                } icon: {
                    Image(systemName: "bell.fill")
                }
            }
        case .paused:
            Text(l10n.t("paused"))
        }
    }

    private var primaryTitle: String {
        switch timer.state {
        case .idle: return l10n.t("start")
        case .work: return l10n.t("pause")
        case .paused: return l10n.t("resume")
        }
    }

    private var controls: some View {
        HStack {
            CircleButton(title: l10n.t("stop")) {
                timer.startStop()
            }
            .disabled(timer.state == .idle)
            .opacity(timer.state == .idle ? 0.4 : 1)
            Spacer()
            if timer.state != .idle {
                Button {
                    timer.reset()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 34, height: 34)
                        .contentShape(Circle())
                }
                .buttonStyle(CircleButtonStyle(tint: nil))
                .help(l10n.t("reset"))
                .transition(.scale.combined(with: .opacity))
                Spacer()
            }
            CircleButton(title: primaryTitle,
                         tint: timer.state == .work ? pauseOrange : startGreen) {
                if timer.state == .idle {
                    timer.startStop()
                } else {
                    timer.pauseResume()
                }
            }
            // Return belongs to the number field while editing
            .keyboardShortcut(edit.editing ? nil : .defaultAction)
        }
        .padding(.horizontal, 6)
    }
}

// MARK: - Statistics page

private struct StatsPage: View {
    @ObservedObject var ui: PopoverUIState
    @ObservedObject private var stats = TBStats.shared
    @ObservedObject private var l10n = L10n.shared

    private var calendar: Calendar { Calendar.current }

    private var isCurrentMonth: Bool {
        calendar.isDate(ui.statsMonth, equalTo: Date(), toGranularity: .month)
    }

    private func formatted(_ date: Date, _ template: String) -> String {
        let f = DateFormatter()
        f.locale = l10n.locale
        f.setLocalizedDateFormatFromTemplate(template)
        return f.string(from: date)
    }

    private func shiftMonth(_ delta: Int) {
        if let month = calendar.date(byAdding: .month, value: delta, to: ui.statsMonth) {
            withAnimation(.easeOut(duration: 0.2)) { ui.statsMonth = month }
        }
    }

    var body: some View {
        let days = stats.days(inMonthOf: ui.statsMonth).reversed()
        let longest = max(days.map { stats.seconds(on: $0) }.max() ?? 0, 1)
        VStack(alignment: .leading, spacing: 16) {
            summary
            monthSwitcher
            SettingsSection(title: l10n.t("stats.daily")) {
                if stats.total(inMonthOf: ui.statsMonth) == 0 {
                    Text(l10n.t("stats.none"))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                } else {
                    ForEach(Array(days.enumerated()), id: \.element) { index, day in
                        dayRow(day, longest: longest, divider: index < days.count - 1)
                    }
                }
            }
        }
        .font(.system(size: 13))
    }

    private var summary: some View {
        HStack(spacing: 10) {
            tile(title: l10n.t("stats.today"), value: stats.today)
            tile(title: isCurrentMonth ? l10n.t("stats.monthTotal") : formatted(ui.statsMonth, "yMMMM"),
                 value: stats.total(inMonthOf: ui.statsMonth))
        }
    }

    private func tile(title: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .lineLimit(1)
            Text(formatDuration(value))
                .font(.system(size: 18, weight: .semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(0.05))
        )
    }

    private var monthSwitcher: some View {
        HStack {
            Button { shiftMonth(-1) } label: {
                Image(systemName: "chevron.left").frame(width: 24, height: 22).contentShape(Rectangle())
            }
            Spacer()
            Text(formatted(ui.statsMonth, "yMMMM"))
                .font(.system(size: 13, weight: .semibold))
            Spacer()
            Button { shiftMonth(1) } label: {
                Image(systemName: "chevron.right").frame(width: 24, height: 22).contentShape(Rectangle())
            }
            .disabled(isCurrentMonth)
            .opacity(isCurrentMonth ? 0.3 : 1)
        }
        .buttonStyle(.plain)
    }

    private func dayRow(_ day: Date, longest: Double, divider: Bool) -> some View {
        let seconds = stats.seconds(on: day)
        let isToday = calendar.isDateInToday(day)
        return VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text(formatted(day, "MMMdEEE"))
                    .fontWeight(isToday ? .semibold : .regular)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .frame(width: 86, alignment: .leading)
                GeometryReader { geo in
                    Capsule()
                        .fill(pauseOrange.opacity(seconds > 0 ? 0.85 : 0))
                        .frame(width: max(geo.size.width * seconds / longest, seconds > 0 ? 4 : 0), height: 6)
                        .frame(maxHeight: .infinity, alignment: .center)
                }
                .frame(height: 14)
                Text(seconds >= 60 ? formatDuration(seconds, compact: true) : "—")
                    .monospacedDigit()
                    .foregroundColor(seconds >= 60 ? .primary : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(width: 92, alignment: .trailing)
            }
            .padding(.vertical, 6)
            if divider { Divider() }
        }
    }
}

// MARK: - Popover

private enum Page {
    case timer, settings, stats
}

private class PopoverUIState: ObservableObject {
    @Published var page = Page.timer
    @Published var statsMonth = Date()
}

struct TBPopoverView: View {
    @ObservedObject var timer: TBTimer
    @ObservedObject private var l10n = L10n.shared
    @StateObject private var ui = PopoverUIState()
    @ObservedObject private var hotKeys = HotKeyCenter.shared
    @ObservedObject private var stats = TBStats.shared

    var body: some View {
        ZStack {
            switch ui.page {
            case .timer:
                timerPage
                    .transition(.move(edge: .leading).combined(with: .opacity))
            case .settings:
                subpage(title: l10n.t("tab.settings")) {
                    SettingsPage(timer: timer, player: timer.player)
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            case .stats:
                subpage(title: l10n.t("stats.title")) {
                    StatsPage(ui: ui)
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .frame(width: 290)
        .clipped()
        .onReceive(NotificationCenter.default.publisher(for: .tbPopoverWillShow)) { _ in
            // Always open on the timer, with this month's figures
            ui.page = .timer
            ui.statsMonth = Date()
        }
    }

    private func go(to page: Page) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.88)) {
            ui.page = page
        }
    }

    private var timerPage: some View {
        VStack(spacing: 10) {
            TimerPage(timer: timer)
                .padding(.top, 18)
                .padding(.horizontal, 16)
            todayCard
                .padding(.horizontal, 14)
                .padding(.top, 4)
            Divider()
                .padding(.horizontal, 14)
            VStack(spacing: 0) {
                MenuRow(title: l10n.t("tab.settings") + "…", shortcut: "⌘,") {
                    go(to: .settings)
                }
                .keyboardShortcut(",")
                MenuRow(title: l10n.t("quit"),
                        shortcut: hotKeys.hotKeys[.quit]?.displayString ?? "") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 6)
        }
    }

    /// Today's focus total; opens the statistics
    private var todayCard: some View {
        Button {
            go(to: .stats)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(pauseOrange)
                Text(l10n.t("stats.today"))
                Spacer()
                Text(formatDuration(stats.today))
                    .monospacedDigit()
                    .foregroundColor(.secondary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .font(.system(size: 13))
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.primary.opacity(0.05))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func subpage<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            ZStack {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                HStack {
                    Button {
                        go(to: .timer)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .semibold))
                            .frame(width: 26, height: 26)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.cancelAction)
                    Spacer()
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            Divider()
            ScrollView {
                content()
                    .padding(14)
            }
            .frame(height: 440)
        }
    }
}
