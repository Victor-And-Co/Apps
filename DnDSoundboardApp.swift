//
//  DnDSoundboardApp.swift
//  DnD Soundboard
//
//  Created by Victor Hoang on 7/22/25.
//


import SwiftUI

@main
struct DnDSoundboardApp: App {
    @StateObject private var audioManager = AudioManager.shared  // global audio manager
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(audioManager)  // provide audio manager to child views if needed
        }
    }
}