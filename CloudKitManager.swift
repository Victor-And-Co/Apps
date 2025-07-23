//
//  CloudKitManager.swift
//  DnD Soundboard
//
//  Created by Victor Hoang on 7/22/25.
//


import CloudKit

/// CloudKit helper to save and retrieve Soundscape records for iCloud sync.
class CloudKitManager {
    static let shared = CloudKitManager()
    private let privateDB = CKContainer.default().privateCloudDatabase
    
    private init() {}
    
    /// Save a soundscape to the user's private iCloud database.
    func saveSoundscape(_ soundscape: Soundscape) async throws {
        // Create a CKRecord for the soundscape
        let record = CKRecord(recordType: "Soundscape", recordID: CKRecord.ID(recordName: soundscape.id.uuidString))
        record["name"] = soundscape.name as CKRecordValue
        // Encode soundInfos to JSON and store as a string
        if let data = try? JSONEncoder().encode(soundscape.soundInfos),
           let jsonString = String(data: data, encoding: .utf8) {
            record["soundsData"] = jsonString as CKRecordValue
        }
        // If there are user-imported files, consider adding as CKAsset (not implemented here for simplicity)
        
        _ = try await privateDB.save(record)  // save to iCloud
    }
    
    /// Fetch all saved soundscapes from iCloud.
    func fetchSoundscapes() async throws -> [Soundscape] {
        let query = CKQuery(recordType: "Soundscape", predicate: NSPredicate(value: true))
        var resultSoundscapes: [Soundscape] = []
        // Perform the query
        let (matchedRecords, _) = try await privateDB.records(matching: query)
        for (_, recordResult) in matchedRecords {
            if case .success(let record) = recordResult {
                if let name = record["name"] as? String,
                   let dataString = record["soundsData"] as? String,
                   let data = dataString.data(using: .utf8) {
                    if let infos = try? JSONDecoder().decode([SoundInfo].self, from: data) {
                        let scape = Soundscape(name: name, soundInfos: infos)
                        // Use the CloudKit recordName (UUID string) as id if needed
                        resultSoundscapes.append(scape)
                    }
                }
            }
        }
        return resultSoundscapes
    }
    
    /// Delete a soundscape from iCloud by record ID (UUID string).
    func deleteSoundscape(recordName: String) async throws {
        let recordID = CKRecord.ID(recordName: recordName)
        try await privateDB.deleteRecord(withID: recordID)
    }
    
    /// Check iCloud account status (for Settings display).
    func getAccountStatus() async -> CKAccountStatus {
        do {
            return try await CKContainer.default().accountStatus()
        } catch {
            return .couldNotDetermine
        }
    }
}