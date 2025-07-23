import Foundation
import AVFoundation

/// Model class representing a sound (either from Freesound or local) that can be played in the mixer.
class SoundItem: ObservableObject, Identifiable {
    enum SourceType {
        case freesound(id: Int)  // sound from Freesound API (identified by Freesound ID)
        case local               // user-imported local file
    }
    
    // Unique identifier for Identifiable (use UUID so local and remote can coexist)
    let id: UUID = UUID()
    
    // Properties
    let name: String            // Display name of the sound
    let source: SourceType      // Source type (to handle differently if needed)
    let fileURL: URL            // URL to the local audio file for playback
    
    @Published var volume: Float    // Volume 0.0 - 1.0
    @Published var isMuted: Bool
    
    private var audioPlayer: AVAudioPlayer?
    private var originalVolume: Float = 1.0  // to restore volume after unmute
    
    init(name: String, fileURL: URL, source: SourceType, volume: Float = 1.0) {
        self.name = name
        self.fileURL = fileURL
        self.source = source
        self.volume = volume
        self.isMuted = false
        self.originalVolume = volume
        prepareAudioPlayer()
    }
    
    /// Prepare the AVAudioPlayer for this sound and start looping playback
    private func prepareAudioPlayer() {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
            guard let player = audioPlayer else { return }
            player.numberOfLoops = -1  // loop indefinitely [oai_citation:2‡reddit.com](https://www.reddit.com/r/swift/comments/meji5h/how_do_i_loop_audio_in_my_code/#:~:text=player.numberOfLoops%20%3D%20,number%20for%20a%20finite%20amount)
            player.volume = volume
            player.prepareToPlay()
            player.play()
            // Configure audio session for playback/mix (once globally, see AudioManager)
        } catch {
            print("Error initializing audio player for \(name): \(error)")
        }
    }
    
    /// Update the player's volume, taking mute into account
    func updateVolume(_ newVolume: Float) {
        volume = newVolume
        if !isMuted {
            audioPlayer?.volume = newVolume
        }
    }
    
    /// Mute or unmute this sound
    func toggleMute() {
        if isMuted {
            // Unmute: restore volume
            isMuted = false
            audioPlayer?.volume = volume
        } else {
            // Mute: remember current volume, then set volume to 0
            isMuted = true
            audioPlayer?.volume = 0.0
        }
    }
    
    /// Stop playback and clean up the player
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
}
