//
//  InvoicesRepository.swift
//  FlowLedger
//
//  Created by Pankaj Gaikar on 02/11/25.
//

import Foundation
import SwiftData

@MainActor
class InvoicesRepository {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func fetchAll() throws -> [Invoice] {
        let descriptor = FetchDescriptor<Invoice>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return try modelContext.fetch(descriptor)
    }
    
    func fetchByStatus(_ status: InvoiceStatus) throws -> [Invoice] {
        let descriptor = FetchDescriptor<Invoice>(
            predicate: #Predicate { $0.status == status.rawValue },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func fetch(id: UUID) throws -> Invoice? {
        let descriptor = FetchDescriptor<Invoice>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    func create(_ invoice: Invoice) throws {
        modelContext.insert(invoice)
        try modelContext.save()
    }
    
    func update(_ invoice: Invoice) throws {
        try modelContext.save()
    }
    
    func delete(_ invoice: Invoice) throws {
        modelContext.delete(invoice)
        try modelContext.save()
    }
    
    func generateInvoiceNumber() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let datePrefix = formatter.string(from: Date())
        let randomSuffix = Int.random(in: 1000...9999)
        return "INV-\(datePrefix)-\(randomSuffix)"
    }
    
    func calculateTotals(invoice: Invoice) -> (subtotal: Decimal, tax: Decimal, total: Decimal) {
        let subtotal = invoice.lineItems.reduce(Decimal(0)) { $0 + $1.total }
        let afterDiscount = subtotal - invoice.discount
        let tax = afterDiscount * invoice.taxRate
        let total = afterDiscount + tax
        return (subtotal, tax, total)
    }
}

