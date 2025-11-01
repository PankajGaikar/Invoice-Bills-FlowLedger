//
//  SubscriptionDetailViewModel.swift
//  FlowLedger
//
//  Created by Pankaj Gaikar on 02/11/25.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
class SubscriptionDetailViewModel: ObservableObject {
    @Published var subscription: Subscription?
    @Published var name: String = ""
    @Published var amount: Decimal = 0
    @Published var cadence: SubscriptionCadence = .monthly
    @Published var nextDueDate: Date = Date()
    @Published var category: String = ""
    @Published var reminderDaysBefore: Int = 2
    @Published var notes: String = ""
    @Published var isPaused: Bool = false
    @Published var isSaving: Bool = false
    @Published var errorMessage: String?
    
    private let repository: SubscriptionsRepository
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext, subscription: Subscription? = nil) {
        self.modelContext = modelContext
        self.repository = SubscriptionsRepository(modelContext: modelContext)
        self.subscription = subscription
        
        if let subscription = subscription {
            loadSubscription(subscription)
        }
    }
    
    private func loadSubscription(_ subscription: Subscription) {
        self.subscription = subscription
        name = subscription.name
        amount = subscription.amount
        cadence = subscription.subscriptionCadence
        nextDueDate = subscription.nextDueDate
        category = subscription.category ?? ""
        reminderDaysBefore = subscription.reminderDaysBefore
        notes = subscription.notes ?? ""
        isPaused = subscription.isPaused
    }
    
    func save() {
        isSaving = true
        errorMessage = nil
        
        if let subscription = subscription {
            // Update existing
            subscription.name = name
            subscription.amount = amount
            subscription.subscriptionCadence = cadence
            subscription.nextDueDate = nextDueDate
            subscription.category = category.isEmpty ? nil : category
            subscription.reminderDaysBefore = reminderDaysBefore
            subscription.notes = notes.isEmpty ? nil : notes
            subscription.isPaused = isPaused
        } else {
            // Create new
            subscription = Subscription(
                name: name,
                amount: amount,
                cadence: cadence,
                nextDueDate: nextDueDate,
                category: category.isEmpty ? nil : category,
                reminderDaysBefore: reminderDaysBefore,
                notes: notes.isEmpty ? nil : notes,
                isPaused: isPaused
            )
            modelContext.insert(subscription!)
        }
        
        do {
            try repository.create(subscription!)
            isSaving = false
        } catch {
            errorMessage = "Failed to save subscription: \(error.localizedDescription)"
            isSaving = false
        }
    }
}

