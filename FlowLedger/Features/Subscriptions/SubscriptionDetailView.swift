//
//  SubscriptionDetailView.swift
//  FlowLedger
//
//  Created by Pankaj Gaikar on 02/11/25.
//

import SwiftUI
import SwiftData

struct SubscriptionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: SubscriptionDetailViewModel
    
    init(modelContext: ModelContext, subscription: Subscription?) {
        _viewModel = StateObject(wrappedValue: SubscriptionDetailViewModel(modelContext: modelContext, subscription: subscription))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Bill Name", text: $viewModel.name)
                    
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("0", value: $viewModel.amount, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                    
                    Picker("Cadence", selection: $viewModel.cadence) {
                        Text("Weekly").tag(SubscriptionCadence.weekly)
                        Text("Monthly").tag(SubscriptionCadence.monthly)
                        Text("Quarterly").tag(SubscriptionCadence.quarterly)
                        Text("Yearly").tag(SubscriptionCadence.yearly)
                    }
                    
                    DatePicker("Next Due Date", selection: $viewModel.nextDueDate, displayedComponents: .date)
                    
                    TextField("Category (optional)", text: $viewModel.category)
                }
                
                Section("Reminders") {
                    Stepper("Days before due: \(viewModel.reminderDaysBefore)", value: $viewModel.reminderDaysBefore, in: 0...7)
                    
                    Toggle("Paused", isOn: $viewModel.isPaused)
                }
                
                Section("Notes") {
                    TextField("Notes (optional)", text: $viewModel.notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(viewModel.subscription == nil ? "New Bill" : viewModel.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.save()
                        dismiss()
                    }
                    .disabled(viewModel.isSaving || viewModel.name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    SubscriptionDetailView(modelContext: ModelContext(try! ModelContainer(for: Subscription.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))), subscription: nil)
}

