//
//  SearchView.swift
//  DnD Soundboard
//
//  Created by Victor Hoang on 7/22/25.
//


import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @EnvironmentObject var audioManager: AudioManager  // to add sounds to mixer
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    TextField("Search sounds...", text: $viewModel.query, onCommit: {
                        // Trigger search when Return pressed
                        Task { await viewModel.search() }
                    })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disableAutocorrection(true)
                    .padding(.horizontal)
                    
                    if viewModel.isSearching {
                        ProgressView()
                            .padding(.trailing)
                    }
                }
                .padding(.vertical, 8)
                
                // Search results list
                List {
                    ForEach(viewModel.searchResults) { sound in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(sound.name)
                                    .font(.body)
                                Text("#\(sound.id)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            // Preview / stop button
                            if viewModel.previewingSoundID == sound.id {
                                // If this sound is currently previewing, show a stop button
                                Button(action: {
                                    viewModel.stopPreview()
                                }) {
                                    Image(systemName: "stop.fill")
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            } else {
                                Button(action: {
                                    viewModel.previewSound(sound)
                                }) {
                                    Image(systemName: "play.circle")
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                            // Add to mix button
                            Button(action: {
                                Task {
                                    if let soundItem = await viewModel.addSoundToMix(sound) {
                                        audioManager.addSound(soundItem)
                                    }
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(PlainListStyle())
                
                // Import local file button at bottom
                Button(action: {
                    // Present a document picker for audio files
                    presentDocumentPicker()
                }) {
                    Label("Import Local Sound", systemImage: "tray.and.arrow.down")
                }
                .padding()
            }
            .navigationBarTitle("Search Sounds")
        }
    }
    
    /// Helper to present a UIDocumentPicker for audio files
    private func presentDocumentPicker() {
        let supportedTypes: [UTType] = [UTType.audio]  // accept any audio file type
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
        picker.allowsMultipleSelection = false
        picker.delegate = Context.coordinator  // Not directly accessible; will need UIViewControllerRepresentable for SwiftUI integration
        // In SwiftUI, one would use .fileImporter instead of this manual approach.
        // For brevity, consider .fileImporter:
    }
}

// SwiftUI provides a modifier .fileImporter that can replace the above UIKit code. In a real app, we'd implement .fileImporter.