import AVFoundation
import SwiftUI

class TBPlayer: ObservableObject {
    private var windupSound: AVAudioPlayer
    private var dingSound: AVAudioPlayer
    private var tickingSound: AVAudioPlayer

    @AppStorage("windupVolume") var windupVolume: Double = 1.0 {
        didSet {
            setVolume(windupSound, windupVolume)
        }
    }
    @AppStorage("dingVolume") var dingVolume: Double = 1.0 {
        didSet {
            setVolume(dingSound, dingVolume)
        }
    }
    @AppStorage("tickingVolume") var tickingVolume: Double = 1.0 {
        didSet {
            setVolume(tickingSound, tickingVolume)
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
        dingSound = Self.load("ding")
        tickingSound = Self.load("ticking")

        windupSound.prepareToPlay()
        dingSound.prepareToPlay()
        tickingSound.numberOfLoops = -1
        tickingSound.prepareToPlay()

        setVolume(windupSound, windupVolume)
        setVolume(dingSound, dingVolume)
        setVolume(tickingSound, tickingVolume)
    }

    func playWindup() {
        windupSound.play()
    }

    func playDing() {
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
