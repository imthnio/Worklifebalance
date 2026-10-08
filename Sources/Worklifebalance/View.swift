import SwiftUI

private struct TimerSettingsView: View {
    @ObservedObject var timer: TBTimer
    @ObservedObject private var l10n = L10n.shared

    var body: some View {
        VStack {
            Stepper(value: $timer.workIntervalLength, in: 1 ... 120) {
                HStack {
                    Text(l10n.t("timer.workLength"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(l10n.t("timer.minFormat", timer.workIntervalLength))
                }
            }
            Toggle(isOn: $timer.autoRestart) {
                Text(l10n.t("timer.autoRestart"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }.toggleStyle(.switch)
        }
        .padding(4)
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
        .padding(4)
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
        .padding(4)
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
        .padding(4)
    }
}

private enum ChildView {
    case timer, settings, shortcuts, sounds
}

private class PopoverUIState: ObservableObject {
    @Published var buttonHovered = false
    @Published var activeChildView = ChildView.timer
}

struct TBPopoverView: View {
    @ObservedObject var timer: TBTimer
    @ObservedObject private var l10n = L10n.shared
    @StateObject private var ui = PopoverUIState()

    private var mainLabel: String {
        switch timer.state {
        case .idle:
            return l10n.t("start")
        case .work, .paused:
            return ui.buttonHovered ? l10n.t("stop") : timer.timeLeftString
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Button {
                    timer.startStop()
                    TBStatusItem.shared.closePopover(nil)
                } label: {
                    Text(mainLabel)
                        /*
                          When appearance is set to "Dark" and accent color is set to "Graphite"
                          "defaultAction" button label's color is set to the same color as the
                          button, making the button look blank.
                         */
                        .foregroundColor(Color.white)
                        .font(.system(.body).monospacedDigit())
                        .frame(maxWidth: .infinity)
                }
                .onHover { over in
                    ui.buttonHovered = over
                }
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)

                if timer.state != .idle {
                    Button {
                        timer.pauseResume()
                    } label: {
                        Image(systemName: timer.state == .paused ? "play.fill" : "pause.fill")
                            .frame(width: 20)
                    }
                    .controlSize(.large)
                    .help(timer.state == .paused ? l10n.t("resume") : l10n.t("pause"))

                    Button {
                        timer.reset()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .frame(width: 20)
                    }
                    .controlSize(.large)
                    .help(l10n.t("reset"))
                }
            }

            if timer.state == .paused {
                Text(l10n.t("paused"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }

            Picker("", selection: $ui.activeChildView) {
                Text(l10n.t("tab.timer")).tag(ChildView.timer)
                Text(l10n.t("tab.settings")).tag(ChildView.settings)
                Text(l10n.t("tab.shortcuts")).tag(ChildView.shortcuts)
                Text(l10n.t("tab.sounds")).tag(ChildView.sounds)
            }
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .pickerStyle(.segmented)

            GroupBox {
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

            Group {
                Button {
                    NSApp.activate(ignoringOtherApps: true)
                    NSApp.orderFrontStandardAboutPanel()
                } label: {
                    Text(l10n.t("about"))
                    Spacer()
                    Text("⌘ A").foregroundColor(Color.gray)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("a")
                Button {
                    NSApplication.shared.terminate(self)
                } label: {
                    Text(l10n.t("quit"))
                    Spacer()
                    Text("⌘ Q").foregroundColor(Color.gray)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("q")
            }
        }
        .frame(width: 300)
        .padding(12)
    }
}
