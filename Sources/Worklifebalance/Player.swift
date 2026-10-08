import AVFoundation
import SwiftUI
import UniformTypeIdentifiers

/// Plays the user's own alert sound when time is up; without one the app stays silent
class TBPlayer: ObservableObject {
    private var alertSound: AVAudioPlayer?

    @AppStorage("customAlertVolume") var customAlertVolume: Double = 1.0 {
        didSet {
            alertSound?.setVolume(Float(customAlertVolume), fadeDuration: 0)
        }
    }
    /// Path of a user-chosen audio file; empty means no sound
    @AppStorage("customAlertSoundPath") var customAlertSoundPath = "" {
        didSet {
            loadAlertSound()
        }
    }

    init() {
        loadAlertSound()
    }

    /// Whether a sound is set but can't be played (moved, deleted, unsupported)
    var customAlertSoundUnavailable: Bool {
        !customAlertSoundPath.isEmpty && alertSound == nil
    }

    private func loadAlertSound() {
        alertSound?.stop()
        alertSound = nil
        guard !customAlertSoundPath.isEmpty else { return }
        let url = URL(fileURLWithPath: customAlertSoundPath)
        guard let sound = try? AVAudioPlayer(contentsOf: url) else {
            print("cannot load alert sound: \(customAlertSoundPath)")
            return
        }
        sound.prepareToPlay()
        sound.setVolume(Float(customAlertVolume), fadeDuration: 0)
        alertSound = sound
    }

    func chooseCustomAlertSound() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.audio]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        NSApp.activate(ignoringOtherApps: true)
        if panel.runModal() == .OK, let url = panel.url {
            customAlertSoundPath = url.path
        }
    }

    func playAlert() {
        // The file may have been replaced or restored since it was chosen
        if alertSound == nil {
            loadAlertSound()
        }
        alertSound?.currentTime = 0
        alertSound?.play()
    }
}
