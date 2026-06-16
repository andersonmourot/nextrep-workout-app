import AVFoundation
import UserNotifications

class AudioManager {
    static let shared = AudioManager()
    
    private var audioPlayer: AVAudioPlayer?
    private var soundTimer: Timer?
    
    private init() {
        setupAudioSession()
        setupNotifications()
    }
    
    // MARK: - Audio Session Setup
    
    func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            
            // Configure for playback with other audio mixing
            try session.setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers, .allowBluetoothA2DP]
            )
            
            try session.setActive(true)
            print("Audio session configured successfully")
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    // MARK: - Notification Setup
    
    private func setupNotifications() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    // MARK: - Sound Playback
    
    func playBellSound() {
        // Play a system sound for the bell
        playSystemSound(1016) // 1016 is a bell-like system sound
    }
    
    func playCountdownBeep() {
        playSystemSound(1054) // Short beep
    }
    
    func playWorkoutCompleteSound() {
        playSystemSound(1020) // Success sound
    }
    
    private func playSystemSound(_ soundID: SystemSoundID) {
        AudioServicesPlaySystemSound(soundID)
    }
    
    // MARK: - Background Timer Scheduling
    
    func scheduleTimerCompletionNotification(after seconds: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Rest Timer Complete"
        content.body = "Get ready for your next set!"
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(seconds),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "rest-timer-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    func cancelPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    // MARK: - Sound File Playback (for custom sounds)
    
    func playCustomSound(named fileName: String, fileExtension: String = "mp3") {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: fileExtension) else {
            print("Sound file not found: \(fileName).\(fileExtension)")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Error playing sound file: \(error)")
        }
    }
    
    // MARK: - Cleanup
    
    func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Error deactivating audio session: \(error)")
        }
    }
}