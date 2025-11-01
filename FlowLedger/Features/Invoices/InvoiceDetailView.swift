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
        _viewModel = StateObject(wrappedValue: InvoiceDetailViewModel(modelContext: modelContext, invoice: invoice))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Client") {
                    TextField("Client Name", text: $viewModel.clientName)
                    TextField("Email (optional)", text: $viewModel.clientEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                Section("Line Items") {
                    ForEach(Array(viewModel.lineItems.enumerated()), id: \.element.id) { index, item in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.itemDescription)
                                Text("\(item.quantity, specifier: "%.2f") × \(item.unitPrice, specifier: "%.2f")")
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
            .navigationTitle(viewModel.invoice?.invoiceNumber ?? "New Invoice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
            .onChange(of: viewModel.taxRate) { _, _ in
                viewModel.updateTotals()
            }
            .onChange(of: viewModel.discount) { _, _ in
                viewModel.updateTotals()
            }
            .sheet(isPresented: $showingShareSheet) {
                if let pdfURL = pdfURL {
                    ShareSheet(items: [pdfURL])
                }
            }
        }
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

