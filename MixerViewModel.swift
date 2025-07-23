//
//  MixerViewModel.swift
//  DnD Soundboard
//
//  Created by Victor Hoang on 7/22/25.
//


import SwiftUI

@MainActor
class MixerViewModel: ObservableObject {
    @ObservedObject var audioManager = AudioManager.shared  // observe the shared AudioManager
    
    // These functions simply wrap AudioManager for convenience, could also use AudioManager directly in the view.
    func removeSound(_ sound: SoundItem) {
        audioManager.removeSound(sound)
    }
    
    func clearMixer() {
        audioManager.clearAllSounds()
    }
}