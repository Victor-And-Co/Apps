//
//  SettingsView.swift
//  DnD Soundboard
//
//  Created by Victor Hoang on 7/22/25.
//


import SwiftUI

struct SettingsView: View {
    @State private var iCloudStatus: CKAccountStatus = .couldNotDetermine
    @State private var showingClearedAlert: Bool = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Account")) {
                    HStack {
                        Text("iCloud Account")
                        Spacer()
                        switch iCloudStatus {
                        case .available:
                            Text("Signed In").foregroundColor(.green)
                        case .noAccount:
                            Text("Not Signed In").foregroundColor(.red)
                        case .restricted:
                            Text("Restricted").foregroundColor(.orange)
                        case .couldNotDetermine:
                            Text("Unknown").foregroundColor(.gray)
                        @unknown default:
                            Text("Unknown").foregroundColor(.gray)
                        }
                    }
                    .onAppear {
                        Task {
                            iCloudStatus = await CloudKitManager.shared.getAccountStatus()
                        }
                    }
                }
                
                Section(header: Text("Storage")) {
                    Button("Clear Downloaded Sounds") {
                        LocalFileManager.clearDownloads(keepImports: true)
                        showingClearedAlert = true
                    }
                    .alert("Cleared downloaded sounds.", isPresented: $showingClearedAlert) {
                        Button("OK", role: .cancel) {}
                    }
                    Text("Clearing will remove all Freesound audio files saved offline. Imported sounds are kept.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    }
                    HStack {
                        Text("Build")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "")
                    }
                    Text("DnD Soundboard allows you to mix ambient sounds and music for tabletop gaming. Sounds courtesy of Freesound.org.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 4)
                }
            }
            .navigationBarTitle("Settings")
        }
    }
}