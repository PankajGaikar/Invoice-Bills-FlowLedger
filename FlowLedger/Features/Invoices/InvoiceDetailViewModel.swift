//
//  InvoiceDetailViewModel.swift
//  FlowLedger
//
//  Created by Pankaj Gaikar on 02/11/25.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
class InvoiceDetailViewModel: ObservableObject {
    @Published var invoice: Invoice?
    @Published var clientName: String = ""
    @Published var clientEmail: String = ""
    @Published var lineItems: [LineItem] = []
    @Published var taxRate: Decimal = 0
    @Published var discount: Decimal = 0
    @Published var notes: String = ""
    @Published var dueDate: Date = Date()
    @Published var isSaving: Bool = false
    @Published var errorMessage: String?
    
    private let repository: InvoicesRepository
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext, invoice: Invoice? = nil) {
        self.modelContext = modelContext
        self.repository = InvoicesRepository(modelContext: modelContext)
        self.invoice = invoice
        
        if let invoice = invoice {
            loadInvoice(invoice)
        } else {
            // Create new invoice
            self.invoice = Invoice(
                invoiceNumber: repository.generateInvoiceNumber(),
                status: .draft,
                dueDate: Calendar.current.date(byAdding: .day, value: 30, to: Date())
            )
            self.dueDate = self.invoice?.dueDate ?? Date()
        }
    }
    
    private func loadInvoice(_ invoice: Invoice) {
        self.invoice = invoice
        clientName = invoice.client?.name ?? ""
        clientEmail = invoice.client?.email ?? ""
        lineItems = invoice.lineItems
        taxRate = invoice.taxRate
        discount = invoice.discount
        notes = invoice.notes ?? ""
        dueDate = invoice.dueDate ?? Date()
    }
    
    func addLineItem(description: String, quantity: Double, unitPrice: Decimal) {
        guard let invoice = invoice else { return }
        let item = LineItem(description: description, quantity: quantity, unitPrice: unitPrice)
        item.invoice = invoice
        modelContext.insert(item)
        invoice.lineItems.append(item)
        lineItems.append(item)
        updateTotals()
    }
    
    func removeLineItem(at index: Int) {
        guard index < lineItems.count, let invoice = invoice else { return }
        let item = lineItems[index]
        invoice.lineItems.removeAll { $0.id == item.id }
        modelContext.delete(item)
        lineItems.remove(at: index)
        updateTotals()
    }
    
    func updateTotals() {
        guard let invoice = invoice else { return }
        invoice.lineItems = lineItems
        let (subtotal, tax, total) = repository.calculateTotals(invoice: invoice)
        invoice.subtotal = subtotal
        invoice.taxRate = taxRate
        invoice.discount = discount
        invoice.total = total
    }
    
    func save() {
        guard let invoice = invoice else { return }
        isSaving = true
        errorMessage = nil
        
        // Create or update client if name is provided
        if !clientName.isEmpty {
            if invoice.client == nil {
                let client = Client(name: clientName, email: clientEmail.isEmpty ? nil : clientEmail)
                modelContext.insert(client)
                invoice.client = client
            } else {
                invoice.client?.name = clientName
                invoice.client?.email = clientEmail.isEmpty ? nil : clientEmail
            }
        }
        
        invoice.dueDate = dueDate
        invoice.notes = notes.isEmpty ? nil : notes
        
        // Ensure line items are properly linked
        for item in lineItems {
            item.invoice = invoice
        }
        
        updateTotals()
        
        do {
            try modelContext.save()
            isSaving = false
        } catch {
            errorMessage = "Failed to save invoice: \(error.localizedDescription)"
            isSaving = false
        }
    }
    
    var subtotal: Decimal {
        lineItems.reduce(Decimal(0)) { $0 + $1.total }
    }
    
    var tax: Decimal {
        (subtotal - discount) * taxRate
    }
    
    var total: Decimal {
        subtotal - discount + tax
    }
}

