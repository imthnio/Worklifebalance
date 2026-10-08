import AVFoundation
import SwiftUI
import UniformTypeIdentifiers

class TBPlayer: ObservableObject {
    private var windupSound: AVAudioPlayer
    private var defaultDingSound: AVAudioPlayer
    private var customDingSound: AVAudioPlayer?
    private var dingSound: AVAudioPlayer { customDingSound ?? defaultDingSound }

    @AppStorage("windupVolume") var windupVolume: Double = 1.0 {
        didSet {
            setVolume(windupSound, windupVolume)
        }
    }
    @AppStorage("dingVolume") var dingVolume: Double = 1.0 {
        didSet {
            setVolume(defaultDingSound, dingVolume)
        }
    }
    @AppStorage("customAlertVolume") var customAlertVolume: Double = 1.0 {
        didSet {
            if let custom = customDingSound {
                setVolume(custom, customAlertVolume)
            }
        }
    }
    /// Path of a user-chosen audio file played when time is up; empty means the built-in sound
    @AppStorage("customAlertSoundPath") var customAlertSoundPath = "" {
        didSet {
            loadCustomDing()
        }
    }

    private func setVolume(_ sound: AVAudioPlayer, _ volume: Double) {
        sound.setVolume(Float(volume), fadeDuration: 0)
    }

    private static func load(_ name: String) -> AVAudioPlayer {
        guard let url = Bundle.main.url(forResource: name, withExtension: "m4a") else {
            fatalError("Missing sound resource: \(name)")
        }
        do {
            return try AVAudioPlayer(contentsOf: url)
        } catch {
            fatalError("Error initializing players: \(error)")
        }
    }

    init() {
        windupSound = Self.load("windup")
        defaultDingSound = Self.load("ding")

        windupSound.prepareToPlay()
        defaultDingSound.prepareToPlay()

        setVolume(windupSound, windupVolume)
        setVolume(defaultDingSound, dingVolume)
        loadCustomDing()
    }

    /// Whether a custom sound is set but can't be played (moved, deleted, unsupported)
    var customAlertSoundUnavailable: Bool {
        !customAlertSoundPath.isEmpty && customDingSound == nil
    }

    private func loadCustomDing() {
        customDingSound?.stop()
        customDingSound = nil
        guard !customAlertSoundPath.isEmpty else { return }
        let url = URL(fileURLWithPath: customAlertSoundPath)
        guard let sound = try? AVAudioPlayer(contentsOf: url) else {
            print("cannot load custom alert sound: \(customAlertSoundPath)")
            return
        }
        sound.prepareToPlay()
        setVolume(sound, customAlertVolume)
        customDingSound = sound
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

    func playWindup() {
        windupSound.play()
    }

    func playDing() {
        // The file may have been replaced or removed since it was chosen
        if customDingSound == nil, !customAlertSoundPath.isEmpty {
            loadCustomDing()
        }
        dingSound.currentTime = 0
        dingSound.play()
    }
}
