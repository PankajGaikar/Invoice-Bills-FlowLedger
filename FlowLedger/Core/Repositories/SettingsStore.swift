//
//  SettingsStore.swift
//  FlowLedger
//
//  Created by Pankaj Gaikar on 02/11/25.
//

import Foundation
import SwiftData

@MainActor
class SettingsStore {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func getSettings() throws -> AppSettings {
        let descriptor = FetchDescriptor<AppSettings>()
        if let existing = try modelContext.fetch(descriptor).first {
            return existing
        }
        
        // Create default settings
        let defaultSettings = AppSettings()
        modelContext.insert(defaultSettings)
        try modelContext.save()
        return defaultSettings
    }
    
    func updateSettings(_ settings: AppSettings) throws {
        settings.updatedAt = Date()
        try modelContext.save()
    }
}

