import AVFoundation
import SwiftUI
import UniformTypeIdentifiers

class TBPlayer: ObservableObject {
    private var windupSound: AVAudioPlayer
    private var defaultDingSound: AVAudioPlayer
    private var customDingSound: AVAudioPlayer?
    private var dingSound: AVAudioPlayer { customDingSound ?? defaultDingSound }
    private var tickingSound: AVAudioPlayer

    @AppStorage("windupVolume") var windupVolume: Double = 1.0 {
        didSet {
            setVolume(windupSound, windupVolume)
        }
    }
    @AppStorage("dingVolume") var dingVolume: Double = 1.0 {
        didSet {
            setVolume(defaultDingSound, dingVolume)
            if let custom = customDingSound {
                setVolume(custom, dingVolume)
            }
        }
    }
    @AppStorage("tickingVolume") var tickingVolume: Double = 1.0 {
        didSet {
            setVolume(tickingSound, tickingVolume)
        }
    }
    /// Path of a user-chosen audio file played when time is up; empty means the built-in sound
    @AppStorage("customAlertSoundPath") var customAlertSoundPath = "" {
        didSet {
            loadCustomDing()
        }
    }
    @AppStorage("tickingEnabled") var tickingEnabled = true {
        didSet {
            if !tickingEnabled {
                tickingSound.stop()
            } else if tickingWanted {
                tickingSound.play()
            }
        }
    }

    /// Whether the timer is running and wants the ticking sound
    private var tickingWanted = false

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
        tickingSound = Self.load("ticking")

        windupSound.prepareToPlay()
        defaultDingSound.prepareToPlay()
        tickingSound.numberOfLoops = -1
        tickingSound.prepareToPlay()

        setVolume(windupSound, windupVolume)
        setVolume(defaultDingSound, dingVolume)
        setVolume(tickingSound, tickingVolume)
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
        setVolume(sound, dingVolume)
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

    func startTicking() {
        tickingWanted = true
        if tickingEnabled {
            tickingSound.play()
        }
    }

    func stopTicking() {
        tickingWanted = false
        tickingSound.stop()
    }

    func toggleTicking() {
        tickingEnabled.toggle()
    }
}
