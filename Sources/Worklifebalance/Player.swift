import AVFoundation
import SwiftUI
import UniformTypeIdentifiers

/// Plays the user's own alert sound when time is up; without one the app stays silent
class TBPlayer: ObservableObject {
    private static let volumeKey = "customAlertVolume"
    private static let pathKey = "customAlertSoundPath"

    private var alertSound: AVAudioPlayer?

    @Published var customAlertVolume: Double {
        didSet {
            let clamped = min(max(customAlertVolume, 0), 2)
            if clamped != customAlertVolume {
                customAlertVolume = clamped
                return
            }
            UserDefaults.standard.set(clamped, forKey: Self.volumeKey)
            alertSound?.setVolume(Float(clamped), fadeDuration: 0)
        }
    }
    /// Path of a user-chosen audio file; empty means no sound
    @Published var customAlertSoundPath: String {
        didSet {
            UserDefaults.standard.set(customAlertSoundPath, forKey: Self.pathKey)
            loadAlertSound()
        }
    }
    /// Whether a sound is set but can't be played (moved, deleted, unsupported)
    @Published private(set) var customAlertSoundUnavailable = false

    init() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: Self.volumeKey) != nil {
            customAlertVolume = min(max(defaults.double(forKey: Self.volumeKey), 0), 2)
        } else {
            customAlertVolume = 1.0
        }
        customAlertSoundPath = defaults.string(forKey: Self.pathKey) ?? ""
        loadAlertSound()
    }

    private func loadAlertSound() {
        alertSound?.stop()
        alertSound = nil
        guard !customAlertSoundPath.isEmpty else {
            customAlertSoundUnavailable = false
            return
        }
        let url = URL(fileURLWithPath: customAlertSoundPath)
        guard let sound = try? AVAudioPlayer(contentsOf: url) else {
            print("cannot load alert sound: \(customAlertSoundPath)")
            customAlertSoundUnavailable = true
            return
        }
        sound.prepareToPlay()
        sound.setVolume(Float(customAlertVolume), fadeDuration: 0)
        alertSound = sound
        customAlertSoundUnavailable = false
    }

    /// Re-checks a previously missing file when settings are opened
    func refreshAlertSound() {
        if customAlertSoundUnavailable || (alertSound == nil && !customAlertSoundPath.isEmpty) {
            loadAlertSound()
        }
    }

    func chooseCustomAlertSound() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.audio]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        TBStatusItem.shared.withPopoverPinned {
            NSApp.activate(ignoringOtherApps: true)
            if panel.runModal() == .OK, let url = panel.url {
                customAlertSoundPath = url.path
            }
        }
    }

    func playAlert() {
        // The file may have been replaced or restored since it was chosen
        if alertSound == nil {
            loadAlertSound()
        }
        alertSound?.setVolume(Float(customAlertVolume), fadeDuration: 0)
        alertSound?.currentTime = 0
        alertSound?.play()
    }
}
