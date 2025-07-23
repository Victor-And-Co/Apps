//
//  AudioManager.swift
//  DnD Soundboard
//
//  Created by Victor Hoang on 7/22/25.
//


import AVFoundation
import SwiftUI

/// Manages the collection of sounds currently in the mix and the audio session configuration.
class AudioManager: ObservableObject {
    static let shared = AudioManager()
    
    @Published private(set) var currentSounds: [SoundItem] = []  // sounds in the current mix
    
    private init() {
        configureAudioSession()
    }
    
    /// Configure the audio session for playback with mixing capabilities.
    private func configureAudioSession() {
        do {
            // Use playback category with mixWithOthers so soundboard audio can mix with other apps if desired.
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category: \(error)")
        }
    }
    
    /// Add a new SoundItem to the mix and start playing it.
    func addSound(_ sound: SoundItem) {
        currentSounds.append(sound)
        // SoundItem initializer already starts playback, so nothing else needed here.
    }
    
    /// Remove a sound from the mix by its index (or SoundItem) and stop its audio.
    func removeSound(_ sound: SoundItem) {
        if let index = currentSounds.firstIndex(where: { $0.id == sound.id }) {
            // Stop audio playback and remove from list
            currentSounds[index].stop()
            currentSounds.remove(at: index)
        }
    }
    
    /// Remove all sounds (e.g., when loading a new soundscape) and stop their audio.
    func clearAllSounds() {
        for sound in currentSounds {
            sound.stop()
        }
        currentSounds.removeAll()
    }
}