//
//  Reminder.swift
//  FlowLedger
//
//  Created by Pankaj Gaikar on 02/11/25.
//

import Foundation
import SwiftData

@Model
final class Reminder {
    var id: UUID
    var subscription: Subscription?
    var scheduledDate: Date
    var notificationId: String // UNNotificationRequest identifier
    var isSnoozed: Bool
    var createdAt: Date
    
    init(subscription: Subscription?, scheduledDate: Date, notificationId: String) {
        self.id = UUID()
        self.subscription = subscription
        self.scheduledDate = scheduledDate
        self.notificationId = notificationId
        self.isSnoozed = false
        self.createdAt = Date()
    }
}

