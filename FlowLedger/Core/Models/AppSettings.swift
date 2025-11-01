//
//  AppSettings.swift
//  FlowLedger
//
//  Created by Pankaj Gaikar on 02/11/25.
//

import Foundation
import SwiftData

@Model
final class AppSettings {
    var id: UUID
    var defaultTaxRate: Decimal
    var currencySymbol: String
    var enableReminders: Bool
    var reminderTime: Date // time of day for reminders
    var preferredPDFTemplate: String // "clean" or "noir"
    var isDarkMode: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(
        defaultTaxRate: Decimal = 0,
        currencySymbol: String = "₹",
        enableReminders: Bool = true,
        reminderTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date(),
        preferredPDFTemplate: String = "clean",
        isDarkMode: Bool = false
    ) {
        self.id = UUID()
        self.defaultTaxRate = defaultTaxRate
        self.currencySymbol = currencySymbol
        self.enableReminders = enableReminders
        self.reminderTime = reminderTime
        self.preferredPDFTemplate = preferredPDFTemplate
        self.isDarkMode = isDarkMode
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

