//
//  SubscriptionsRepository.swift
//  FlowLedger
//
//  Created by Pankaj Gaikar on 02/11/25.
//

import Foundation
import SwiftData

@MainActor
class SubscriptionsRepository {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func fetchAll() throws -> [Subscription] {
        let descriptor = FetchDescriptor<Subscription>(sortBy: [SortDescriptor(\.nextDueDate, order: .forward)])
        return try modelContext.fetch(descriptor)
    }
    
    func fetchActive() throws -> [Subscription] {
        let descriptor = FetchDescriptor<Subscription>(
            predicate: #Predicate { $0.isPaused == false },
            sortBy: [SortDescriptor(\.nextDueDate, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func fetchByCategory(_ category: String) throws -> [Subscription] {
        let descriptor = FetchDescriptor<Subscription>(
            predicate: #Predicate { $0.category == category },
            sortBy: [SortDescriptor(\.nextDueDate, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func fetch(id: UUID) throws -> Subscription? {
        let descriptor = FetchDescriptor<Subscription>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    func create(_ subscription: Subscription) throws {
        modelContext.insert(subscription)
        try modelContext.save()
    }
    
    func update(_ subscription: Subscription) throws {
        try modelContext.save()
    }
    
    func delete(_ subscription: Subscription) throws {
        modelContext.delete(subscription)
        try modelContext.save()
    }
    
    func markAsPaid(_ subscription: Subscription) throws {
        subscription.advanceNextDueDate()
        let payment = BillPayment(subscription: subscription, amount: subscription.amount, paidDate: Date())
        modelContext.insert(payment)
        try modelContext.save()
    }
}

