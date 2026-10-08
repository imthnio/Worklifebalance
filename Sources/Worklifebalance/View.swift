import SwiftUI

private struct TimerSettingsView: View {
    @ObservedObject var timer: TBTimer
    @ObservedObject private var l10n = L10n.shared

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
        VStack {
            HStack {
                Text(l10n.t("timer.workLength"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                TextField("", value: workLength, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 48)
                Text(l10n.t("timer.minUnit"))
                Stepper("", value: $timer.workIntervalLength, in: workLengthRange)
                    .labelsHidden()
            }
            Toggle(isOn: $timer.autoRestart) {
                Text(l10n.t("timer.autoRestart"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }.toggleStyle(.switch)
        }
    }
}

private struct SettingsView: View {
    @ObservedObject var timer: TBTimer
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var launchAtLogin = LaunchAtLogin.shared

    var body: some View {
        VStack {
            HStack {
                Text(l10n.t("settings.language"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Picker("", selection: $l10n.language) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(lang.nativeName).tag(lang)
                    }
                }
                .labelsHidden()
                .fixedSize()
            }
            Toggle(isOn: $timer.showTimerInMenuBar) {
                Text(l10n.t("settings.showTimer"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }.toggleStyle(.switch)
                .onChange(of: timer.showTimerInMenuBar) { _ in
                    timer.updateTimeLeft()
                }
            Toggle(isOn: $launchAtLogin.isEnabled) {
                Text(l10n.t("settings.launchAtLogin"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }.toggleStyle(.switch)
        }
    }
}

private struct ShortcutsView: View {
    @ObservedObject private var l10n = L10n.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(HotKeyAction.allCases) { action in
                HStack {
                    Text(l10n.t(action.titleKey))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    HotKeyRecorder(action: action)
                }
            }
            HStack {
                Text(l10n.t("shortcut.hint"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Button(l10n.t("shortcut.restoreDefaults")) {
                    HotKeyCenter.shared.restoreDefaults()
                }
                .controlSize(.small)
            }
        }
    }
}

private struct VolumeSlider: View {
    @Binding var volume: Double

    var body: some View {
        Slider(value: $volume, in: 0...2) {
            Text(String(format: "%.1f", volume))
        }.gesture(TapGesture(count: 2).onEnded({
            volume = 1.0
        }))
    }
}

private struct SoundsView: View {
    @ObservedObject var player: TBPlayer
    @ObservedObject private var l10n = L10n.shared

    private var columns = [
        GridItem(.flexible()),
        GridItem(.fixed(110))
    ]

    init(player: TBPlayer) {
        self.player = player
    }

    var body: some View {
        VStack {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 4) {
                Text(l10n.t("sounds.windup"))
                VolumeSlider(volume: $player.windupVolume)
                Text(l10n.t("sounds.ding"))
                VolumeSlider(volume: $player.dingVolume)
                Text(l10n.t("sounds.ticking"))
                VolumeSlider(volume: $player.tickingVolume)
            }
            Toggle(isOn: $player.tickingEnabled) {
                Text(l10n.t("shortcut.toggleTicking"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }.toggleStyle(.switch)
        }
    }
}

// MARK: - Styling

let tomato = Color(red: 0.96, green: 0.33, blue: 0.27)

private struct ControlButtonStyle<S: Shape>: ButtonStyle {
    let prominent: Bool
    let shape: S

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(prominent ? .white : .primary)
            .controlBackground(prominent: prominent, shape: shape)
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

private extension View {
    /// Liquid Glass on macOS 26+, a matching flat fill before that
    @ViewBuilder
    func controlBackground<S: Shape>(prominent: Bool, shape: S) -> some View {
        if #available(macOS 26, *) {
            self.glassEffect(prominent ? .regular.tint(tomato).interactive() : .regular.interactive(),
                             in: shape)
        } else {
            self.background(shape.fill(prominent ? tomato : Color.primary.opacity(0.08)))
        }
    }

    func controlStyle<S: Shape>(prominent: Bool, shape: S) -> some View {
        buttonStyle(ControlButtonStyle(prominent: prominent, shape: shape))
    }

    @ViewBuilder
    func countdownTransition() -> some View {
        if #available(macOS 14, *) {
            self.contentTransition(.numericText(countsDown: true))
        } else {
            self
        }
    }

    func card() -> some View {
        padding(10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.primary.opacity(0.05))
            )
    }
}

private struct CircleControl: View {
    let systemImage: String
    var size: CGFloat = 36
    var prominent = false
    let help: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.38, weight: .semibold))
                .frame(width: size, height: size)
                .contentShape(Circle())
        }
        .controlStyle(prominent: prominent, shape: Circle())
        .help(help)
    }
}

private struct ProgressRing: View {
    let progress: Double
    let active: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: 9)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(colors: [tomato.opacity(0.55), tomato],
                                    center: .center,
                                    startAngle: .degrees(0),
                                    endAngle: .degrees(max(360 * progress, 1))),
                    style: StrokeStyle(lineWidth: 9, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .opacity(active ? 1 : 0.35)
        }
        .animation(.linear(duration: 1), value: progress)
        .animation(.easeInOut(duration: 0.3), value: active)
    }
}

// MARK: - Popover

private enum ChildView: CaseIterable {
    case timer, settings, shortcuts, sounds

    var icon: String {
        switch self {
        case .timer: return "timer"
        case .settings: return "gearshape"
        case .shortcuts: return "command"
        case .sounds: return "speaker.wave.2"
        }
    }

    var titleKey: String {
        switch self {
        case .timer: return "tab.timer"
        case .settings: return "tab.settings"
        case .shortcuts: return "tab.shortcuts"
        case .sounds: return "tab.sounds"
        }
    }
}

private class PopoverUIState: ObservableObject {
    @Published var activeChildView = ChildView.timer
}

struct TBPopoverView: View {
    @ObservedObject var timer: TBTimer
    @ObservedObject private var l10n = L10n.shared
    @StateObject private var ui = PopoverUIState()
    @ObservedObject private var hotKeys = HotKeyCenter.shared

    private var displayTime: String {
        timer.state == .idle
            ? timer.format(seconds: TimeInterval(timer.workIntervalLength * 60))
            : timer.timeLeftString
    }

    private var statusText: String {
        switch timer.state {
        case .idle: return l10n.t("status.ready")
        case .work: return l10n.t("status.focusing")
        case .paused: return l10n.t("paused")
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            clock
            controls
            tabs
            footer
        }
        .frame(width: 280)
        .padding(16)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: timer.state)
    }

    private var clock: some View {
        ZStack {
            ProgressRing(progress: timer.progress, active: timer.state == .work)
            VStack(spacing: 2) {
                Text(displayTime)
                    .font(.system(size: 38, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .countdownTransition()
                    .animation(.spring(response: 0.3, dampingFraction: 0.9), value: displayTime)
                    .opacity(timer.state == .paused ? 0.45 : 1)
                    .animation(timer.state == .paused
                               ? .easeInOut(duration: 0.9).repeatForever()
                               : .default,
                               value: timer.state == .paused)
                Text(statusText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .transition(.opacity)
                    .id(statusText)
            }
        }
        .frame(width: 168, height: 168)
        .padding(.top, 4)
    }

    @ViewBuilder
    private var controls: some View {
        if timer.state == .idle {
            Button {
                timer.startStop()
            } label: {
                Label(l10n.t("start"), systemImage: "play.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 150, height: 36)
                    .contentShape(Capsule())
            }
            .controlStyle(prominent: true, shape: Capsule())
            .keyboardShortcut(.defaultAction)
            .transition(.scale(scale: 0.8).combined(with: .opacity))
        } else {
            HStack(spacing: 18) {
                CircleControl(systemImage: "arrow.counterclockwise",
                              help: l10n.t("reset")) { timer.reset() }
                CircleControl(systemImage: timer.state == .paused ? "play.fill" : "pause.fill",
                              size: 48, prominent: true,
                              help: timer.state == .paused ? l10n.t("resume") : l10n.t("pause")) {
                    timer.pauseResume()
                }
                .keyboardShortcut(.defaultAction)
                CircleControl(systemImage: "stop.fill",
                              help: l10n.t("stop")) { timer.startStop() }
            }
            .transition(.scale(scale: 0.8).combined(with: .opacity))
        }
    }

    private var tabs: some View {
        VStack(spacing: 10) {
            Picker("", selection: $ui.activeChildView.animation(.spring(response: 0.3,
                                                                       dampingFraction: 0.85))) {
                ForEach(ChildView.allCases, id: \.self) { child in
                    Image(systemName: child.icon)
                        .help(l10n.t(child.titleKey))
                        .tag(child)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)

            Group {
                switch ui.activeChildView {
                case .timer:
                    TimerSettingsView(timer: timer)
                case .settings:
                    SettingsView(timer: timer)
                case .shortcuts:
                    ShortcutsView()
                case .sounds:
                    SoundsView(player: timer.player)
                }
            }
            .font(.system(size: 12))
            .controlSize(.small)
            .card()
            .id(ui.activeChildView)
            .transition(.opacity.combined(with: .offset(y: 6)))
        }
    }

    private var footer: some View {
        HStack {
            Button {
                NSApp.activate(ignoringOtherApps: true)
                NSApp.orderFrontStandardAboutPanel()
            } label: {
                Label(l10n.t("about"), systemImage: "info.circle")
            }
            .keyboardShortcut("a")
            Spacer()
            Button {
                NSApplication.shared.terminate(self)
            } label: {
                HStack(spacing: 4) {
                    Text(l10n.t("quit"))
                    Text(hotKeys.hotKeys[.quit]?.displayString ?? "")
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }
        }
        .buttonStyle(.plain)
        .font(.system(size: 12))
        .foregroundColor(.secondary)
    }
}
