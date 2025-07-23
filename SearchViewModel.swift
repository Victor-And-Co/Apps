//
//  SearchViewModel.swift
//  DnD Soundboard
//
//  Created by Victor Hoang on 7/22/25.
//


import SwiftUI

@MainActor
class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var searchResults: [FreesoundSound] = []
    @Published var isSearching: Bool = false
    @Published var previewPlayer: AVAudioPlayer? = nil  // player for previewing a sound
    @Published var previewingSoundID: Int? = nil        // ID of sound currently previewing (to highlight UI)
    
    /// Perform search via FreesoundAPI
    func search() async {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { 
            searchResults = []
            return 
        }
        isSearching = true
        do {
            let results = try await FreesoundAPI.search(query: q)
            // Update UI on main thread
            searchResults = results
        } catch {
            print("Search error: \(error)")
            searchResults = []
        }
        isSearching = false
    }
    
    /// Play a short preview of the given FreesoundSound (using the preview URL).
    func previewSound(_ sound: FreesoundSound) {
        stopPreview()  // stop any existing preview first
        // Determine preview URL (use HQ MP3 if available, otherwise perhaps LQ)
        guard let url = sound.previews.default ?? sound.previews.small else { return }
        previewingSoundID = sound.id
        // Download the preview data and play
        DispatchQueue.global(qos: .background).async {
            if let data = try? Data(contentsOf: url) {
                DispatchQueue.main.async {
                    do {
                        self.previewPlayer = try AVAudioPlayer(data: data)
                        self.previewPlayer?.prepareToPlay()
                        self.previewPlayer?.play()
                    } catch {
                        print("Failed to play preview: \(error)")
                    }
                }
            }
        }
    }
    
    /// Stop the currently playing preview (if any).
    func stopPreview() {
        previewPlayer?.stop()
        previewPlayer = nil
        previewingSoundID = nil
    }
    
    /// When user selects a sound from results to add to the mix, download it and create a SoundItem.
    func addSoundToMix(_ sound: FreesoundSound) async -> SoundItem? {
        // Determine the preview URL to download (we use the HQ mp3 preview for actual mix playback).
        guard let url = sound.previews.default ?? sound.previews.small else {
            return nil
        }
        // Prepare file name for saving (prefix with "freesound_" and use the Freesound ID and .mp3 extension)
        let fileName = "freesound_\(sound.id).mp3"
        do {
            // Download the audio file data and save locally
            let localURL = try await LocalFileManager.downloadFile(from: url, fileName: fileName)
            // Create SoundItem with default volume 1.0
            let soundItem = SoundItem(name: sound.name, fileURL: localURL, source: .freesound(id: sound.id), volume: 1.0)
            return soundItem
        } catch {
            print("Error downloading or saving sound \(sound.id): \(error)")
            return nil
        }
    }
}