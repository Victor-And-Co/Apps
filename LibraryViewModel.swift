//
//  LibraryViewModel.swift
//  DnD Soundboard
//
//  Created by Victor Hoang on 7/22/25.
//


import SwiftUI

@MainActor
class LibraryViewModel: ObservableObject {
    @Published var savedSoundscapes: [Soundscape] = []
    @Published var isLoading: Bool = false
    
    init() {
        // Optionally, load local cached soundscapes or fetch from CloudKit on init
        loadFromCloud()
    }
    
    /// Save the current mix as a new soundscape with the given name.
    func saveCurrentMix(name: String, currentSounds: [SoundItem]) {
        // Construct SoundInfo list from current SoundItems
        let infos = currentSounds.map { item in
            let sourceTypeStr: String
            var freesoundID: Int? = nil
            switch item.source {
            case .freesound(let id):
                sourceTypeStr = "freesound"
                freesoundID = id
            case .local:
                sourceTypeStr = "local"
            }
            let fileName = item.fileURL.lastPathComponent
            return SoundInfo(sourceType: sourceTypeStr, freesoundID: freesoundID, name: item.name, fileName: fileName, volume: item.volume, isMuted: item.isMuted)
        }
        let newSoundscape = Soundscape(name: name, soundInfos: infos)
        savedSoundscapes.append(newSoundscape)
        
        // Save to CloudKit asynchronously
        Task {
            do {
                try await CloudKitManager.shared.saveSoundscape(newSoundscape)
            } catch {
                print("CloudKit save error: \(error)")
            }
        }
    }
    
    /// Load a soundscape (by index or id) into the current mixer.
    func loadSoundscape(_ soundscape: Soundscape) {
        // First clear current mix
        AudioManager.shared.clearAllSounds()
        // For each SoundInfo, recreate the SoundItem and add to mixer
        for info in soundscape.soundInfos {
            let fileURL = LocalFileManager.soundsDirectory.appendingPathComponent(info.fileName)
            if !FileManager.default.fileExists(atPath: fileURL.path) {
                // If file not present (e.g., on a new device), attempt to download if it's a Freesound item
                if info.sourceType == "freesound", let fid = info.freesoundID {
                    // Construct a FreesoundSound stub to use the SearchViewModel's download function
                    // (In practice, we might store the preview URL or re-search by ID)
                    if let url = URL(string: "https://freesound.org/data/previews/\(fid/1000)/\(fid)_\(fid)-hq.mp3") {
                        // Try downloading (this is a heuristic: Freesound file URLs often embed the ID, but a full API fetch by ID would be better)
                        Task {
                            do {
                                let newURL = try await LocalFileManager.downloadFile(from: url, fileName: info.fileName)
                                let soundItem = SoundItem(name: info.name, fileURL: newURL, source: .freesound(id: fid), volume: info.volume)
                                if info.isMuted {
                                    soundItem.toggleMute()
                                }
                                AudioManager.shared.addSound(soundItem)
                            } catch {
                                print("Failed to download missing file \(info.fileName): \(error)")
                            }
                        }
                    }
                }
                // If it's a local file and missing, skip (can't retrieve without the user providing it again).
            } else {
                // File exists locally, just create the SoundItem
                let source: SoundItem.SourceType = (info.sourceType == "freesound" && info.freesoundID != nil) ? .freesound(id: info.freesoundID!) : .local
                let soundItem = SoundItem(name: info.name, fileURL: fileURL, source: source, volume: info.volume)
                if info.isMuted {
                    soundItem.toggleMute()
                }
                AudioManager.shared.addSound(soundItem)
            }
        }
    }
    
    /// Fetch saved soundscapes from CloudKit (iCloud).
    func loadFromCloud() {
        isLoading = true
        Task {
            do {
                let scapes = try await CloudKitManager.shared.fetchSoundscapes()
                // Merge or replace local list with cloud list
                savedSoundscapes = scapes
            } catch {
                print("CloudKit fetch error: \(error)")
            }
            isLoading = false
        }
    }
    
    /// Delete a saved soundscape (both locally and from CloudKit).
    func deleteSoundscape(at indexSet: IndexSet) {
        for index in indexSet {
            let scape = savedSoundscapes[index]
            // Remove locally
            savedSoundscapes.remove(at: index)
            // Remove from CloudKit
            Task {
                try? await CloudKitManager.shared.deleteSoundscape(recordName: scape.id.uuidString)
            }
        }
    }
}