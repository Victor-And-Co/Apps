//
//  MixerView.swift
//  DnD Soundboard
//
//  Created by Victor Hoang on 7/22/25.
//


import SwiftUI

struct MixerView: View {
    @EnvironmentObject var audioManager: AudioManager
    @StateObject private var viewModel = MixerViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                if audioManager.currentSounds.isEmpty {
                    Text("No sounds in the mix.\nAdd sounds from Search.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    List {
                        ForEach(audioManager.currentSounds) { sound in
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(sound.name).font(.headline)
                                    Spacer()
                                    // Mute/Unmute button
                                    Button(action: {
                                        sound.toggleMute()
                                    }) {
                                        Image(systemName: sound.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                            .foregroundColor(sound.isMuted ? .red : .primary)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                    // Remove button
                                    Button(action: {
                                        viewModel.removeSound(sound)
                                    }) {
                                        Image(systemName: "trash")
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                }
                                // Volume slider (0 to 1)
                                HStack {
                                    Image(systemName: "speaker.fill")
                                    Slider(value: Binding(get: {
                                        sound.volume
                                    }, set: { newVal in
                                        sound.updateVolume(Float(newVal))
                                    }), in: 0...1)
                                    Image(systemName: "speaker.wave.3.fill")
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationBarTitle("Mixer")
            .navigationBarItems(trailing:
                // A Clear button to remove all sounds from the mix
                Button(action: {
                    viewModel.clearMixer()
                }) {
                    Text("Clear All")
                }
                .disabled(audioManager.currentSounds.isEmpty)
            )
        }
    }
}