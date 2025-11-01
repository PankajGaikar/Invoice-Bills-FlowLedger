//
//  LineItem.swift
//  FlowLedger
//
//  Created by Pankaj Gaikar on 02/11/25.
//

import Foundation
import SwiftData

@Model
final class LineItem: Identifiable {
    var id: UUID
    var itemDescription: String
    var quantity: Double
    var unitPrice: Decimal
    var createdAt: Date
    var invoice: Invoice?
    
    init(description: String, quantity: Double, unitPrice: Decimal) {
        self.id = UUID()
        self.itemDescription = description
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.createdAt = Date()
    }
    
    var total: Decimal {
        Decimal(quantity) * unitPrice
    }
}

