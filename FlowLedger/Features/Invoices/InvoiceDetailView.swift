//
//  InvoiceDetailView.swift
//  FlowLedger
//
//  Created by Pankaj Gaikar on 02/11/25.
//

import SwiftUI
import SwiftData
import UIKit

struct InvoiceDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: InvoiceDetailViewModel
    @State private var showingShareSheet = false
    @State private var pdfURL: URL?
    
    init(modelContext: ModelContext, invoice: Invoice?) {
        let viewModel = InvoiceDetailViewModel(modelContext: modelContext, invoice: invoice)
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            invoiceForm
                .navigationTitle(viewModel.invoice?.invoiceNumber ?? "New Invoice")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    toolbarContent
                }
                .onChange(of: viewModel.taxRate) { _, _ in
                    viewModel.updateTotals()
                }
                .onChange(of: viewModel.discount) { _, _ in
                    viewModel.updateTotals()
                }
                .sheet(isPresented: $showingShareSheet) {
                    if let url = pdfURL {
                        ShareSheet(items: [url])
                    }
                }
        }
    }
    
    @ViewBuilder
    private var invoiceForm: some View {
        Form {
            clientSection
            lineItemsSection
            detailsSection
            totalsSection
            statusSection
        }
    }
    
    @ViewBuilder
    private var clientSection: some View {
        Section("Client") {
            TextField("Client Name", text: $viewModel.clientName)
            TextField("Email (optional)", text: $viewModel.clientEmail)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
        }
    }
    
    @ViewBuilder
    private var lineItemsSection: some View {
        Section("Line Items") {
            ForEach(Array(viewModel.lineItems.enumerated()), id: \.element.id) { index, item in
                HStack {
                    VStack(alignment: .leading) {
                        Text(item.itemDescription)
                        Text(formatLineItemPrice(quantity: item.quantity, unitPrice: item.unitPrice))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    CurrencyText(amount: item.total)
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    viewModel.removeLineItem(at: index)
                }
            }
            
            Button("Add Line Item") {
                viewModel.addLineItem(
                    description: "Item",
                    quantity: 1,
                    unitPrice: 0
                )
            }
        }
    }
    
    @ViewBuilder
    private var detailsSection: some View {
        Section("Details") {
            DatePicker("Due Date", selection: $viewModel.dueDate, displayedComponents: .date)
            
            HStack {
                Text("Tax Rate")
                Spacer()
                TextField("0.18", value: $viewModel.taxRate, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
            }
            
            HStack {
                Text("Discount")
                Spacer()
                TextField("0", value: $viewModel.discount, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
            }
            
            TextField("Notes (optional)", text: $viewModel.notes, axis: .vertical)
                .lineLimit(3...6)
        }
    }
    
    @ViewBuilder
    private var totalsSection: some View {
        Section("Totals") {
            HStack {
                Text("Subtotal")
                Spacer()
                CurrencyText(amount: viewModel.subtotal)
            }
            
            HStack {
                Text("Tax")
                Spacer()
                CurrencyText(amount: viewModel.tax)
            }
            
            HStack {
                Text("Total")
                    .font(Theme.bodyFont(size: 18, weight: .bold))
                Spacer()
                CurrencyText(amount: viewModel.total, font: Theme.monospacedFont(size: 18))
            }
        }
    }
    
    @ViewBuilder
    private var statusSection: some View {
        if let invoice = viewModel.invoice {
            Section("Status") {
                Picker("Status", selection: Binding(
                    get: { invoice.invoiceStatus },
                    set: { newStatus in
                        invoice.invoiceStatus = newStatus
                        if newStatus == .paid {
                            invoice.paidDate = Date()
                        }
                        viewModel.updateTotals()
                    }
                )) {
                    Text("Draft").tag(InvoiceStatus.draft)
                    Text("Sent").tag(InvoiceStatus.sent)
                    Text("Paid").tag(InvoiceStatus.paid)
                }
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                dismiss()
            }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Save") {
                viewModel.save()
                dismiss()
            }
            .disabled(viewModel.isSaving)
        }
        ToolbarItem(placement: .primaryAction) {
            if viewModel.invoice != nil {
                Button {
                    exportPDF()
                } label: {
                    Label("Share PDF", systemImage: "square.and.arrow.up")
                }
            }
        }
    }
    
    private func formatLineItemPrice(quantity: Double, unitPrice: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        let priceString = formatter.string(from: unitPrice as NSDecimalNumber) ?? "0.00"
        return String(format: "%.2f × %@", quantity, priceString)
    }
    
    private func exportPDF() {
        guard let invoice = viewModel.invoice else { return }
        pdfURL = PDFRenderer.shared.renderPDF(for: invoice)
        if pdfURL != nil {
            showingShareSheet = true
            AnalyticsService.shared.logEvent("invoice_pdf_exported", parameters: ["template": "clean"])
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    let schema = Schema([Invoice.self, Client.self, LineItem.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    return InvoiceDetailView(modelContext: ModelContext(container), invoice: nil)
}

