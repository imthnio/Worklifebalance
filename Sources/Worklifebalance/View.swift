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

private struct TimerPage: View {
    @ObservedObject var timer: TBTimer
    @ObservedObject private var l10n = L10n.shared

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
    }

    private var clock: some View {
        ZStack {
            ProgressRing(progress: timer.progress, active: timer.state == .work)
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
                subtitle
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 196, height: 196)
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
            .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 6)
    }
}

// MARK: - Popover

private enum Page {
    case timer, settings
}

private class PopoverUIState: ObservableObject {
    @Published var page = Page.timer
}

struct TBPopoverView: View {
    @ObservedObject var timer: TBTimer
    @ObservedObject private var l10n = L10n.shared
    @StateObject private var ui = PopoverUIState()
    @ObservedObject private var hotKeys = HotKeyCenter.shared

    var body: some View {
        ZStack {
            switch ui.page {
            case .timer:
                timerPage
                    .transition(.move(edge: .leading).combined(with: .opacity))
            case .settings:
                settingsPage
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .frame(width: 290)
        .clipped()
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

    private var settingsPage: some View {
        VStack(spacing: 0) {
            ZStack {
                Text(l10n.t("tab.settings"))
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
                SettingsPage(timer: timer, player: timer.player)
                    .padding(14)
            }
            .frame(height: 440)
        }
    }
}
