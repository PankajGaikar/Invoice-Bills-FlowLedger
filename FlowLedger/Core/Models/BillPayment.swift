//
//  BillPayment.swift
//  FlowLedger
//
//  Created by Pankaj Gaikar on 02/11/25.
//

import Foundation
import SwiftData

@Model
final class BillPayment {
    var id: UUID
    var subscription: Subscription?
    var amount: Decimal
    var paidDate: Date
    var createdAt: Date
    
    init(subscription: Subscription?, amount: Decimal, paidDate: Date) {
        self.id = UUID()
        self.subscription = subscription
        self.amount = amount
        self.paidDate = paidDate
        self.createdAt = Date()
    }
}

