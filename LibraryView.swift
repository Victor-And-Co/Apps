import SwiftUI

struct LibraryView: View {
    @StateObject private var viewModel = LibraryViewModel()
    @EnvironmentObject var audioManager: AudioManager
    
    @State private var newMixName: String = ""
    @State private var showingSaveAlert: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.savedSoundscapes.isEmpty {
                    Text("No soundscapes saved.")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    List {
                        ForEach(viewModel.savedSoundscapes) { scape in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(scape.name).font(.headline)
                                    Text("\(scape.soundInfos.count) sounds").font(.caption).foregroundColor(.gray)
                                }
                                Spacer()
                                // Load button
                                Button("Load") {
                                    viewModel.loadSoundscape(scape)
                                    // Switch to Mixer tab if desired (not shown here; user can manually switch)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete { indexSet in
                            viewModel.deleteSoundscape(at: indexSet)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationBarTitle("Library")
            .navigationBarItems(leading:
                // Refresh button to fetch cloud updates
                Button(action: {
                    viewModel.loadFromCloud()
                }) {
                    Image(systemName: "arrow.clockwise")
                },
                trailing:
                // Save current mix button
                Button(action: {
                    // Prompt for name and save
                    if audioManager.currentSounds.isEmpty {
                        // Nothing to save
                        return
                    }
                    showingSaveAlert = true
                }) {
                    Image(systemName: "square.and.arrow.down")
                    Text("Save Mix")
                }
                .disabled(audioManager.currentSounds.isEmpty)
            )
            .alert("Save Soundscape", isPresented: $showingSaveAlert, TextAlert(title: "Enter a name for this soundscape", placeholder: "Name", input: $newMixName, action: {
                if !newMixName.isEmpty {
                    viewModel.saveCurrentMix(name: newMixName, currentSounds: audioManager.currentSounds)
                    newMixName = ""
                }
            }))
            .onAppear {
                // Optionally load from CloudKit on appear if not already loaded
                // (LibraryViewModel already does in init)
            }
        }
    }
}

// A helper for SwiftUI Alert with Text Field
struct TextAlert: ViewModifier {
    @State private var text: String = ""
    let title: String
    let placeholder: String
    @Binding var input: String
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content.alert(isPresented: Binding<Bool>(
            get: { input != "" },
            set: { _ in }
        )) {
            Alert(title: Text(title),
                  message: Text(""),
                  primaryButton: .default(Text("Save"), action: {
                      input = text
                      action()
                  }),
                  secondaryButton: .cancel({
                      text = ""
                  }))
        }
    }
}
