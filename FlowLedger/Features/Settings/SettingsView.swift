//
//  SettingsView.swift
//  FlowLedger
//
//  Created by Pankaj Gaikar on 02/11/25.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [AppSettings]
    @State private var defaultTaxRate: Decimal = 0
    @State private var currencySymbol: String = "₹"
    @State private var enableReminders: Bool = true
    
    var appSettings: AppSettings {
        settings.first ?? AppSettings()
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Preferences") {
                    HStack {
                        Text("Default Tax Rate")
                        Spacer()
                        TextField("0.18", value: $defaultTaxRate, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    HStack {
                        Text("Currency Symbol")
                        Spacer()
                        TextField("₹", text: $currencySymbol)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }
                
                Section("Notifications") {
                    Toggle("Enable Reminders", isOn: $enableReminders)
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Text("FlowLedger helps you manage invoices and bills with a clear cash flow view.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                loadSettings()
            }
            .onChange(of: defaultTaxRate) { _, _ in
                saveSettings()
            }
            .onChange(of: currencySymbol) { _, _ in
                saveSettings()
            }
            .onChange(of: enableReminders) { _, _ in
                saveSettings()
            }
        }
    }
    
    private func loadSettings() {
        let settingsStore = SettingsStore(modelContext: modelContext)
        do {
            let appSettings = try settingsStore.getSettings()
            defaultTaxRate = appSettings.defaultTaxRate
            currencySymbol = appSettings.currencySymbol
            enableReminders = appSettings.enableReminders
        } catch {
            print("Failed to load settings: \(error)")
        }
    }
    
    private func saveSettings() {
        let settingsStore = SettingsStore(modelContext: modelContext)
        do {
            let appSettings = try settingsStore.getSettings()
            appSettings.defaultTaxRate = defaultTaxRate
            appSettings.currencySymbol = currencySymbol
            appSettings.enableReminders = enableReminders
            try settingsStore.updateSettings(appSettings)
        } catch {
            print("Failed to save settings: \(error)")
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: AppSettings.self, inMemory: true)
}

