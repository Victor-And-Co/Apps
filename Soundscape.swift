//
//  Soundscape.swift
//  DnD Soundboard
//
//  Created by Victor Hoang on 7/22/25.
//


import Foundation

/// Model representing a saved soundscape (a collection of sounds with settings).
struct Soundscape: Identifiable, Codable {
    var id: UUID            // unique id for this soundscape
    var name: String        // user-given name for the mix
    var soundInfos: [SoundInfo]  // the list of sounds (with minimal info needed to recreate)
    
    init(name: String, soundInfos: [SoundInfo]) {
        self.id = UUID()
        self.name = name
        self.soundInfos = soundInfos
    }
}

/// Lightweight representation of a sound in a soundscape (for saving/loading).
struct SoundInfo: Codable {
    var sourceType: String      // "freesound" or "local"
    var freesoundID: Int?       // if sourceType is "freesound", the Freesound sound ID
    var name: String            // name of the sound (for display)
    var fileName: String        // local file name where the audio is stored
    var volume: Float
    var isMuted: Bool
}