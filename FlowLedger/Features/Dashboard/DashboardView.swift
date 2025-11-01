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
                                    AxisMarks { value in
                                        AxisGridLine()
                                        AxisValueLabel {
                                            if let intValue = value.as(Double.self) {
                                                let formatter = NumberFormatter()
                                                formatter.numberStyle = .currency
                                                formatter.currencySymbol = "₹"
                                                formatter.maximumFractionDigits = 0
                                                if let formatted = formatter.string(from: NSNumber(value: abs(intValue))) {
                                                    Text(formatted)
                                                        .font(.caption2)
                                                }
                                            }
                                        }
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
            
            // Column 2: Recent Invoices (simplified for now)
            VStack(alignment: .leading, spacing: Theme.spacing2) {
                Text("Recent Invoices")
                    .font(Theme.headingFont(size: 18))
                    .padding(.horizontal, Theme.spacing2)
                
                // TODO: Add recent invoices list
                Text("No recent invoices")
                    .foregroundColor(.secondary)
                    .padding()
            }
            .frame(maxWidth: .infinity)
            .background(Color(uiColor: .systemBackground))
            .cornerRadius(Theme.cardCornerRadius)
            
            // Column 3: Upcoming Bills (simplified for now)
            VStack(alignment: .leading, spacing: Theme.spacing2) {
                Text("Upcoming Bills")
                    .font(Theme.headingFont(size: 18))
                    .padding(.horizontal, Theme.spacing2)
                
                // TODO: Add upcoming bills list
                Text("No upcoming bills")
                    .foregroundColor(.secondary)
                    .padding()
            }
            .frame(maxWidth: .infinity)
            .background(Color(uiColor: .systemBackground))
            .cornerRadius(Theme.cardCornerRadius)
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
                        AxisMarks { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let intValue = value.as(Double.self) {
                                    let formatter = NumberFormatter()
                                    formatter.numberStyle = .currency
                                    formatter.currencySymbol = "₹"
                                    formatter.maximumFractionDigits = 0
                                    if let formatted = formatter.string(from: NSNumber(value: abs(intValue))) {
                                        Text(formatted)
                                            .font(.caption2)
                                    }
                                }
                            }
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

#Preview {
    let schema = Schema([Invoice.self, Subscription.self, AppSettings.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    return DashboardView(modelContext: ModelContext(container))
}

