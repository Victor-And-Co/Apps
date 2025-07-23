//
//  LocalFileManager.swift
//  DnD Soundboard
//
//  Created by Victor Hoang on 7/22/25.
//


import Foundation

struct LocalFileManager {
    // Directory for stored audio files (in Documents/Sounds)
    static let soundsDirectory: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = docs.appendingPathComponent("Sounds", isDirectory: true)
        // Create the directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }()
    
    /// Saves data to a file in the sounds directory with given name.
    static func saveData(_ data: Data, fileName: String) throws -> URL {
        let fileURL = soundsDirectory.appendingPathComponent(fileName)
        try data.write(to: fileURL, options: [.atomic])
        return fileURL
    }
    
    /// Copy a file from a given URL (e.g., imported via UIDocumentPicker) to the sounds directory.
    static func importFile(from sourceURL: URL) throws -> URL {
        let fileName = sourceURL.lastPathComponent
        let destURL = soundsDirectory.appendingPathComponent(fileName)
        // If a file with same name exists, append a number to name to avoid overwrite
        var finalURL = destURL
        var count = 1
        while FileManager.default.fileExists(atPath: finalURL.path) {
            let baseName = sourceURL.deletingPathExtension().lastPathComponent
            let ext = sourceURL.pathExtension
            let newName = "\(baseName)_\(count).\(ext)"
            finalURL = soundsDirectory.appendingPathComponent(newName)
            count += 1
        }
        try FileManager.default.copyItem(at: sourceURL, to: finalURL)
        return finalURL
    }
    
    /// Download the file at the given URL and save it with the provided file name.
    static func downloadFile(from url: URL, fileName: String) async throws -> URL {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try saveData(data, fileName: fileName)
    }
    
    /// Remove all downloaded files (e.g., Freesound files) from the sounds directory.
    /// If keepImports is true, user-imported files are preserved.
    static func clearDownloads(keepImports: Bool = true) {
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: soundsDirectory, includingPropertiesForKeys: nil, options: [])
            for fileURL in contents {
                if keepImports {
                    // If preserving imported files, skip those that don't start with our prefix for downloads
                    if !fileURL.lastPathComponent.hasPrefix("freesound_") {
                        continue
                    }
                }
                try FileManager.default.removeItem(at: fileURL)
            }
        } catch {
            print("Error clearing files: \(error)")
        }
    }
}