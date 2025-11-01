//
//  InvoiceListView.swift
//  FlowLedger
//
//  Created by Pankaj Gaikar on 02/11/25.
//

import SwiftUI
import SwiftData

struct InvoiceListView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: InvoicesViewModel
    @State private var selectedInvoice: Invoice?
    @State private var showingNewInvoice = false
    
    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: InvoicesViewModel(modelContext: modelContext))
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.invoices.isEmpty && !viewModel.isLoading {
                    EmptyStateView(
                        title: "No invoices yet",
                        message: "No invoices yet — let's make your first.",
                        systemImage: "doc.text",
                        actionTitle: "Create Invoice"
                    ) {
                        showingNewInvoice = true
                    }
                } else {
                    List {
                        ForEach(viewModel.invoices) { invoice in
                            NavigationLink(value: invoice) {
                                InvoiceRowView(invoice: invoice)
                            }
                        }
                        .onDelete(perform: deleteInvoices)
                    }
                    .searchable(text: $viewModel.searchText, prompt: "Search invoices")
                    .onChange(of: viewModel.searchText) { _, _ in
                        viewModel.loadInvoices()
                    }
                }
            }
            .navigationTitle("Invoices")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("All") {
                            viewModel.selectedStatus = nil
                            viewModel.loadInvoices()
                        }
                        Button("Draft") {
                            viewModel.selectedStatus = .draft
                            viewModel.loadInvoices()
                        }
                        Button("Sent") {
                            viewModel.selectedStatus = .sent
                            viewModel.loadInvoices()
                        }
                        Button("Paid") {
                            viewModel.selectedStatus = .paid
                            viewModel.loadInvoices()
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingNewInvoice = true
                    } label: {
                        Label("New Invoice", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewInvoice) {
                InvoiceDetailView(modelContext: modelContext, invoice: nil)
            }
            .navigationDestination(for: Invoice.self) { invoice in
                InvoiceDetailView(modelContext: modelContext, invoice: invoice)
            }
            .onAppear {
                viewModel.loadInvoices()
            }
        }
    }
    
    private func deleteInvoices(offsets: IndexSet) {
        for index in offsets {
            viewModel.deleteInvoice(viewModel.invoices[index])
        }
    }
}

struct InvoiceRowView: View {
    let invoice: Invoice
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(invoice.invoiceNumber)
                    .font(Theme.bodyFont(size: 16, weight: .semibold))
                
                if let client = invoice.client {
                    Text(client.name)
                        .font(Theme.bodyFont(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                CurrencyText(amount: invoice.total, font: Theme.monospacedFont(size: 16))
                
                statusBadge
            }
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private var statusBadge: some View {
        let (color, text) = {
            switch invoice.invoiceStatus {
            case .draft: return (Theme.warning, "Draft")
            case .sent: return (Theme.accent, "Sent")
            case .paid: return (Theme.success, "Paid")
            }
        }()
        
        Text(text)
            .font(Theme.bodyFont(size: 12, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .cornerRadius(6)
    }
}

#Preview {
    let schema = Schema([Invoice.self, Client.self, LineItem.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    return InvoiceListView(modelContext: ModelContext(container))
}

