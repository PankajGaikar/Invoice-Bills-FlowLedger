//
//  Invoice.swift
//  FlowLedger
//
//  Created by Pankaj Gaikar on 02/11/25.
//

import Foundation
import SwiftData

enum InvoiceStatus: String, Codable {
    case draft
    case sent
    case paid
}

@Model
final class Invoice {
    var id: UUID
    var invoiceNumber: String
    var status: String // InvoiceStatus as String for SwiftData compatibility
    var client: Client?
    var lineItems: [LineItem]
    var subtotal: Decimal
    var taxRate: Decimal // e.g., 0.18 for 18%
    var discount: Decimal // absolute amount
    var total: Decimal
    var issuedDate: Date
    var dueDate: Date?
    var paidDate: Date?
    var notes: String?
    var createdAt: Date
    
    init(
        invoiceNumber: String,
        status: InvoiceStatus = .draft,
        client: Client? = nil,
        lineItems: [LineItem] = [],
        subtotal: Decimal = 0,
        taxRate: Decimal = 0,
        discount: Decimal = 0,
        total: Decimal = 0,
        dueDate: Date? = nil,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.invoiceNumber = invoiceNumber
        self.status = status.rawValue
        self.client = client
        self.lineItems = lineItems
        self.subtotal = subtotal
        self.taxRate = taxRate
        self.discount = discount
        self.total = total
        self.issuedDate = Date()
        self.dueDate = dueDate
        self.paidDate = nil
        self.notes = notes
        self.createdAt = Date()
    }
    
    var invoiceStatus: InvoiceStatus {
        get { InvoiceStatus(rawValue: status) ?? .draft }
        set { status = newValue.rawValue }
    }
}

