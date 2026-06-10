//
//  AudioManager.swift
//  Lacquer Art - Audio Manager
//

import AVFoundation
import AudioToolbox
import UIKit

/// Audio Manager (using system sounds, ultra-lightweight)
class AudioManager {
    static let shared = AudioManager()

    private init() {}

    /// Sound effect types
    enum SoundEffect {
        case tap        // tap sound
        case carve      // carving sound
        case success    // success sound
        case assemble   // assembly sound
        case lacquer    // lacquer sound
    }

    /// Play sound effect (using system sound ID)
    func play(_ effect: SoundEffect) {
        let soundID: SystemSoundID

        switch effect {
        case .tap:
            soundID = 1104  // system tap sound
        case .carve:
            soundID = 1306  // system slide sound
        case .success:
            soundID = 1007  // system success sound
        case .assemble:
            soundID = 1103  // system connection sound
        case .lacquer:
            soundID = 1105  // system soft sound
        }

        AudioServicesPlaySystemSound(soundID)
    }

    /// Play haptic feedback
    func playHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    /// Play notification haptic
    func playNotificationHaptic(_ type: UINotificationFeedbackGenerator.FeedbackType = .success) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
}