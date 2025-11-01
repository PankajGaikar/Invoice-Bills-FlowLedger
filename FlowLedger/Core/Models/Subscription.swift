//
//  Subscription.swift
//  FlowLedger
//
//  Created by Pankaj Gaikar on 02/11/25.
//

import Foundation
import SwiftData

enum SubscriptionCadence: String, Codable {
    case monthly
    case quarterly
    case yearly
    case weekly
}

@Model
final class Subscription {
    var id: UUID
    var name: String
    var amount: Decimal
    var cadence: String // SubscriptionCadence as String
    var nextDueDate: Date
    var category: String?
    var reminderDaysBefore: Int // e.g., 2 means notify 2 days before
    var notes: String?
    var isPaused: Bool
    var createdAt: Date
    
    init(
        name: String,
        amount: Decimal,
        cadence: SubscriptionCadence,
        nextDueDate: Date,
        category: String? = nil,
        reminderDaysBefore: Int = 2,
        notes: String? = nil,
        isPaused: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.amount = amount
        self.cadence = cadence.rawValue
        self.nextDueDate = nextDueDate
        self.category = category
        self.reminderDaysBefore = reminderDaysBefore
        self.notes = notes
        self.isPaused = isPaused
        self.createdAt = Date()
    }
    
    var subscriptionCadence: SubscriptionCadence {
        get { SubscriptionCadence(rawValue: cadence) ?? .monthly }
        set { cadence = newValue.rawValue }
    }
    
    func advanceNextDueDate() {
        let calendar = Calendar.current
        switch subscriptionCadence {
        case .weekly:
            nextDueDate = calendar.date(byAdding: .weekOfYear, value: 1, to: nextDueDate) ?? nextDueDate
        case .monthly:
            nextDueDate = calendar.date(byAdding: .month, value: 1, to: nextDueDate) ?? nextDueDate
        case .quarterly:
            nextDueDate = calendar.date(byAdding: .month, value: 3, to: nextDueDate) ?? nextDueDate
        case .yearly:
            nextDueDate = calendar.date(byAdding: .year, value: 1, to: nextDueDate) ?? nextDueDate
        }
    }
}

