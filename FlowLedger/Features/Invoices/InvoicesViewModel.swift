//
//  InvoicesViewModel.swift
//  FlowLedger
//
//  Created by Pankaj Gaikar on 02/11/25.
//

import Foundation
import SwiftData
import SwiftUI
import Combine

@MainActor
class InvoicesViewModel: ObservableObject {
    @Published var invoices: [Invoice] = []
    @Published var selectedStatus: InvoiceStatus? = nil
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let repository: InvoicesRepository
    
    init(modelContext: ModelContext) {
        self.repository = InvoicesRepository(modelContext: modelContext)
    }
    
    func loadInvoices() {
        isLoading = true
        errorMessage = nil
        
        do {
            if let status = selectedStatus {
                invoices = try repository.fetchByStatus(status)
            } else {
                invoices = try repository.fetchAll()
            }
            
            if !searchText.isEmpty {
                invoices = invoices.filter { invoice in
                    invoice.invoiceNumber.localizedCaseInsensitiveContains(searchText) ||
                    invoice.client?.name.localizedCaseInsensitiveContains(searchText) ?? false
                }
            }
        } catch {
            errorMessage = "Failed to load invoices: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func deleteInvoice(_ invoice: Invoice) {
        do {
            try repository.delete(invoice)
            loadInvoices()
        } catch {
            errorMessage = "Failed to delete invoice: \(error.localizedDescription)"
        }
    }
    
    func updateInvoiceStatus(_ invoice: Invoice, to status: InvoiceStatus) {
        do {
            invoice.invoiceStatus = status
            if status == .paid {
                invoice.paidDate = Date()
            }
            try repository.update(invoice)
            loadInvoices()
        } catch {
            errorMessage = "Failed to update invoice: \(error.localizedDescription)"
        }
    }
}

