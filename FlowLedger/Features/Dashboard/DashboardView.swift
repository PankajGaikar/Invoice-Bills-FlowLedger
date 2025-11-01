//
//  DashboardView.swift
//  FlowLedger
//
//  Created by Pankaj Gaikar on 02/11/25.
//

import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: DashboardViewModel
    
    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: DashboardViewModel(modelContext: modelContext))
    }
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    var body: some View {
        NavigationStack {
            if isIPad {
                // iPad: 3-column layout
                iPadLayout
            } else {
                // iPhone: Stack layout
                iPhoneLayout
            }
        }
        .navigationTitle("Dashboard")
        .refreshable {
            viewModel.loadMetrics()
        }
        .onAppear {
            viewModel.loadMetrics()
        }
    }
    
    @ViewBuilder
    private var iPhoneLayout: some View {
        ScrollView {
            VStack(spacing: Theme.spacing2) {
                // KPIs
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: Theme.spacing2) {
                        KPICard(
                            title: "Paid Income",
                            value: viewModel.paidIncome,
                            color: Theme.success
                        )
                        KPICard(
                            title: "Bills Due",
                            value: viewModel.billsDue,
                            color: Theme.warning
                        )
                        KPICard(
                            title: "Net",
                            value: viewModel.net,
                            color: viewModel.net >= 0 ? Theme.success : Theme.danger
                        )
                    }
                    .padding(.horizontal, Theme.spacing2)
                    
                    // Forecast Chart
                    if !viewModel.forecast.isEmpty {
                        CardView {
                            VStack(alignment: .leading, spacing: Theme.spacing2) {
                                Text("Next 30 Days Forecast")
                                    .font(Theme.headingFont(size: 18))
                                
                                Chart(viewModel.forecast, id: \.date) { point in
                                    LineMark(
                                        x: .value("Date", point.date, unit: .day),
                                        y: .value("Inflow", point.inflow)
                                    )
                                    .foregroundStyle(Theme.success)
                                    .interpolationMethod(.catmullRom)
                                    
                                    LineMark(
                                        x: .value("Date", point.date, unit: .day),
                                        y: .value("Outflow", -point.outflow)
                                    )
                                    .foregroundStyle(Theme.danger)
                                    .interpolationMethod(.catmullRom)
                                    
                                    AreaMark(
                                        x: .value("Date", point.date, unit: .day),
                                        y: .value("Net", point.inflow - point.outflow)
                                    )
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Theme.accent.opacity(0.3), Theme.accent.opacity(0.0)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                }
                                .frame(height: 250)
                                .chartXAxis {
                                    AxisMarks(values: .stride(by: .day, count: 5)) { value in
                                        AxisGridLine()
                                        AxisValueLabel(format: .dateTime.month().day(), centered: true)
                                    }
                                }
                                .chartYAxis {
                                    AxisMarks(position: .trailing) { value in
                                        AxisGridLine()
                                        AxisValueLabel(format: .currency(code: "INR").precision(.fractionLength(0)))
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, Theme.spacing2)
                    }
                    
                    // Empty state message
                    if viewModel.paidIncome == 0 && viewModel.billsDue == 0 && viewModel.forecast.isEmpty {
                        VStack(spacing: Theme.spacing2) {
                            Text("You're all set for this month.")
                                .font(Theme.headingFont(size: 20))
                                .padding(.top, Theme.spacing3)
                            
                            Text("Add invoices and bills to see your cash flow forecast.")
                                .font(Theme.bodyFont(size: 14))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(Theme.spacing3)
                    }
                }
                .padding(.vertical, Theme.spacing2)
            }
    }
    
    @ViewBuilder
    private var iPadLayout: some View {
        HStack(alignment: .top, spacing: Theme.spacing2) {
            // Column 1: KPIs
            VStack(spacing: Theme.spacing2) {
                KPICard(title: "Paid Income", value: viewModel.paidIncome, color: Theme.success)
                KPICard(title: "Bills Due", value: viewModel.billsDue, color: Theme.warning)
                KPICard(title: "Net", value: viewModel.net, color: viewModel.net >= 0 ? Theme.success : Theme.danger)
            }
            .frame(maxWidth: .infinity)
            
            // Column 2: Recent Invoices
            CardView {
                VStack(alignment: .leading, spacing: Theme.spacing2) {
                    Text("Recent Invoices")
                        .font(Theme.headingFont(size: 18))
                    
                    if viewModel.recentInvoices.isEmpty {
                        Text("No recent invoices")
                            .font(Theme.bodyFont(size: 14))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, Theme.spacing3)
                    } else {
                        ScrollView {
                            VStack(spacing: Theme.spacing) {
                                ForEach(viewModel.recentInvoices) { invoice in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(invoice.invoiceNumber)
                                                .font(Theme.bodyFont(size: 14, weight: .semibold))
                                            if let client = invoice.client {
                                                Text(client.name)
                                                    .font(Theme.bodyFont(size: 12))
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        Spacer()
                                        VStack(alignment: .trailing, spacing: 4) {
                                            CurrencyText(amount: invoice.total, font: Theme.monospacedFont(size: 14))
                                            statusBadge(for: invoice.invoiceStatus)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                    
                                    if invoice.id != viewModel.recentInvoices.last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            
            // Column 3: Upcoming Bills
            CardView {
                VStack(alignment: .leading, spacing: Theme.spacing2) {
                    Text("Upcoming Bills")
                        .font(Theme.headingFont(size: 18))
                    
                    if viewModel.upcomingBills.isEmpty {
                        Text("No upcoming bills")
                            .font(Theme.bodyFont(size: 14))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, Theme.spacing3)
                    } else {
                        ScrollView {
                            VStack(spacing: Theme.spacing) {
                                ForEach(viewModel.upcomingBills) { subscription in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(subscription.name)
                                                .font(Theme.bodyFont(size: 14, weight: .semibold))
                                            Text(formatDueDate(subscription.nextDueDate))
                                                .font(Theme.bodyFont(size: 12))
                                                .foregroundColor(dueDateColor(for: subscription.nextDueDate))
                                        }
                                        Spacer()
                                        CurrencyText(amount: subscription.amount, font: Theme.monospacedFont(size: 14))
                                    }
                                    .padding(.vertical, 4)
                                    
                                    if subscription.id != viewModel.upcomingBills.last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(Theme.spacing2)
        
        // Forecast chart at bottom (full width)
        if !viewModel.forecast.isEmpty {
            CardView {
                VStack(alignment: .leading, spacing: Theme.spacing2) {
                    Text("Next 30 Days Forecast")
                        .font(Theme.headingFont(size: 18))
                    
                    Chart(viewModel.forecast, id: \.date) { point in
                        LineMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Inflow", point.inflow)
                        )
                        .foregroundStyle(Theme.success)
                        .interpolationMethod(.catmullRom)
                        
                        LineMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Outflow", -point.outflow)
                        )
                        .foregroundStyle(Theme.danger)
                        .interpolationMethod(.catmullRom)
                        
                        AreaMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Net", point.inflow - point.outflow)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Theme.accent.opacity(0.3), Theme.accent.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                    .frame(height: 300)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: 5)) { value in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.month().day(), centered: true)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .trailing) { value in
                            AxisGridLine()
                            AxisValueLabel(format: .currency(code: "INR").precision(.fractionLength(0)))
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.spacing2)
            .padding(.bottom, Theme.spacing2)
        }
    }
}

struct KPICard: View {
    let title: String
    let value: Decimal
    let color: Color
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: Theme.spacing) {
                Text(title)
                    .font(Theme.bodyFont(size: 12))
                    .foregroundColor(.secondary)
                
                CurrencyText(amount: value, font: Theme.monospacedFont(size: 20))
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

extension DashboardView {
    @ViewBuilder
    func statusBadge(for status: InvoiceStatus) -> some View {
        let (color, text) = {
            switch status {
            case .draft: return (Theme.warning, "Draft")
            case .sent: return (Theme.accent, "Sent")
            case .paid: return (Theme.success, "Paid")
            }
        }()
        
        Text(text)
            .font(Theme.bodyFont(size: 10, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.1))
            .cornerRadius(4)
    }
    
    func formatDueDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let daysUntil = calendar.dateComponents([.day], from: Date(), to: date).day ?? 0
        
        if daysUntil < 0 {
            return "Overdue"
        } else if daysUntil == 0 {
            return "Due today"
        } else if daysUntil == 1 {
            return "Due tomorrow"
        } else if daysUntil <= 7 {
            return "Due in \(daysUntil) days"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
    
    func dueDateColor(for date: Date) -> Color {
        let calendar = Calendar.current
        let daysUntil = calendar.dateComponents([.day], from: Date(), to: date).day ?? 0
        
        if daysUntil < 0 {
            return Theme.danger
        } else if daysUntil <= 3 {
            return Theme.warning
        } else {
            return .secondary
        }
    }
}

#Preview {
    let schema = Schema([Invoice.self, Subscription.self, AppSettings.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    return DashboardView(modelContext: ModelContext(container))
}

