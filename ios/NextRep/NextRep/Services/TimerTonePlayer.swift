import AudioToolbox
import AVFoundation
import Foundation

/// Plays timer completion sounds as real audio on a `.playback` session with
/// `.duckOthers`, so alerts are audible over music and ignore the Ring/Silent
/// switch (system sounds via AudioServices honor the mute switch and never
/// duck other audio, which made timer completions inaudible while music
/// played).
final class TimerTonePlayer: NSObject, AVAudioPlayerDelegate {
    static let shared = TimerTonePlayer()

    private var player: AVAudioPlayer?
    /// When a scheduled rest-completion tone fired — used so the foreground
    /// watcher doesn't double-play over it.
    private(set) var lastPlayedCompletionAt: Double?
    private var scheduledFor: Double?

    func play(soundId: String) {
        guard let wav = Self.tone(for: soundId) else {
            return
        }

        configureSession()
        do {
            player = try AVAudioPlayer(data: wav)
            player?.delegate = self
            player?.prepareToPlay()
            player?.play()
        } catch {
            player = nil
        }
    }

    /// Short tick used for rest-countdown 3-2-1 cues.
    func playTick() {
        guard let wav = Self.samplesToWav(Self.tone(frequency: 1400, duration: 0.07)) else {
            return
        }
        configureSession()
        player = try? AVAudioPlayer(data: wav)
        player?.delegate = self
        player?.play()
    }

    /// Schedules the rest-complete tone on the device audio clock. With the
    /// `audio` background mode the player fires even while the app is
    /// suspended or the phone is on silent — unlike local notifications,
    /// whose sound honors the Ring/Silent switch and Focus filters.
    /// The session is armed with `.mixWithOthers` while waiting so the user's
    /// music is not ducked for the whole rest period.
    func scheduleCompletion(soundId: String, restEndsAt: Double) {
        cancelScheduled()
        let delay = (restEndsAt / 1000) - Date().timeIntervalSince1970
        guard delay > 0.5, let wav = Self.tone(for: soundId) else {
            return
        }

        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true, options: [])
        #endif
        do {
            let scheduled = try AVAudioPlayer(data: wav)
            scheduled.delegate = self
            scheduled.prepareToPlay()
            scheduled.play(atTime: scheduled.deviceCurrentTime + delay)
            player = scheduled
            scheduledFor = restEndsAt
        } catch {
            deactivateSession()
        }
    }

    func cancelScheduled() {
        guard scheduledFor != nil else { return }
        player?.stop()
        scheduledFor = nil
        deactivateSession()
    }

    /// True when a scheduled tone already fired for `restEndsAt` — lets the
    /// foreground watcher skip a duplicate play.
    func didPlayCompletion(forRestEndsAt restEndsAt: Double) -> Bool {
        guard let lastPlayedCompletionAt else { return false }
        return abs(lastPlayedCompletionAt - restEndsAt) < 2000
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if let scheduledFor {
            lastPlayedCompletionAt = scheduledFor
            self.scheduledFor = nil
        }
        deactivateSession()
    }

    private func configureSession() {
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.duckOthers])
        try? AVAudioSession.sharedInstance().setActive(true, options: [])
        #endif
    }

    private func deactivateSession() {
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        #endif
    }

    private static func tone(for soundId: String) -> Data? {
        switch soundId {
        case "bell":
            return samplesToWav(decayingTone(frequency: 1568, duration: 0.8))
        case "chime":
            return samplesToWav(
                tone(frequency: 1046.5, duration: 0.22)
                    + tone(frequency: 1318.5, duration: 0.3)
            )
        case "alert":
            var samples: [Int16] = []
            for _ in 0..<3 {
                samples += tone(frequency: 988, duration: 0.11)
                samples += Array(repeating: 0, count: Int(44100 * 0.05))
            }
            return samplesToWav(samples)
        default:
            // "beep" and any unknown ids
            return samplesToWav(tone(frequency: 880, duration: 0.28))
        }
    }

    private static func tone(frequency: Double, duration: Double) -> [Int16] {
        let sampleRate = 44100.0
        let count = Int(sampleRate * duration)
        let fadeCount = min(Int(sampleRate * 0.01), count / 4)
        return (0..<count).map { index in
            let t = Double(index) / sampleRate
            var amplitude = 0.5
            if fadeCount > 0 {
                if index < fadeCount {
                    amplitude *= Double(index) / Double(fadeCount)
                } else if index >= count - fadeCount {
                    amplitude *= Double(count - index) / Double(fadeCount)
                }
            }
            return Int16(sin(2 * .pi * frequency * t) * amplitude * Double(Int16.max))
        }
    }

    private static func decayingTone(frequency: Double, duration: Double) -> [Int16] {
        let sampleRate = 44100.0
        let count = Int(sampleRate * duration)
        return (0..<count).map { index in
            let t = Double(index) / sampleRate
            let envelope = exp(-4.0 * t / duration)
            return Int16(sin(2 * .pi * frequency * t) * envelope * 0.6 * Double(Int16.max))
        }
    }

    /// Wraps 16-bit mono PCM samples in a standard 44-byte WAV header.
    private static func samplesToWav(_ samples: [Int16]) -> Data? {
        let sampleRate: UInt32 = 44100
        let dataSize = UInt32(samples.count * 2)
        var data = Data()
        data.reserveCapacity(44 + Int(dataSize))

        func append(_ string: String) {
            data.append(string.data(using: .ascii)!)
        }
        func appendLE<T: FixedWidthInteger>(_ value: T) {
            var v = value.littleEndian
            data.append(Data(bytes: &v, count: MemoryLayout<T>.size))
        }

        append("RIFF")
        appendLE(UInt32(36) + dataSize)
        append("WAVE")
        append("fmt ")
        appendLE(UInt32(16))          // PCM chunk size
        appendLE(UInt16(1))           // PCM format
        appendLE(UInt16(1))           // mono
        appendLE(sampleRate)
        appendLE(sampleRate * 2)      // byte rate
        appendLE(UInt16(2))           // block align
        appendLE(UInt16(16))          // bits per sample
        append("data")
        appendLE(dataSize)
        for sample in samples {
            appendLE(sample)
        }
        return data
    }
}
