//
//  DashboardRepository.swift
//  FlowLedger
//
//  Created by Pankaj Gaikar on 02/11/25.
//

import Foundation
import SwiftData

@MainActor
class DashboardRepository {
    private let modelContext: ModelContext
    private let invoicesRepo: InvoicesRepository
    private let subscriptionsRepo: SubscriptionsRepository
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.invoicesRepo = InvoicesRepository(modelContext: modelContext)
        self.subscriptionsRepo = SubscriptionsRepository(modelContext: modelContext)
    }
    
    struct DashboardMetrics {
        var paidIncome: Decimal
        var billsDue: Decimal
        var net: Decimal
    }
    
    func getThisMonthMetrics() throws -> DashboardMetrics {
        let calendar = Calendar.current
        let now = Date()
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return DashboardMetrics(paidIncome: 0, billsDue: 0, net: 0)
        }
        
        // Paid income: invoices paid this month
        let paidInvoices = try invoicesRepo.fetchByStatus(.paid)
        let paidIncome = paidInvoices
            .filter { invoice in
                guard let paidDate = invoice.paidDate else { return false }
                return paidDate >= startOfMonth && paidDate <= endOfMonth
            }
            .reduce(Decimal(0)) { $0 + $1.total }
        
        // Bills due: active subscriptions with nextDueDate in current month
        let activeSubscriptions = try subscriptionsRepo.fetchActive()
        let billsDue = activeSubscriptions
            .filter { subscription in
                subscription.nextDueDate >= startOfMonth && subscription.nextDueDate <= endOfMonth
            }
            .reduce(Decimal(0)) { $0 + $1.amount }
        
        let net = paidIncome - billsDue
        
        return DashboardMetrics(paidIncome: paidIncome, billsDue: billsDue, net: net)
    }
    
    struct ForecastPoint {
        var date: Date
        var inflow: Decimal
        var outflow: Decimal
    }
    
    func getNext30DaysForecast() throws -> [ForecastPoint] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var points: [ForecastPoint] = []
        
        // Generate 30 days
        for dayOffset in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            
            // Inflow: unpaid invoices due on this date
            let unpaidInvoices = try invoicesRepo.fetchByStatus(.sent)
            let inflow = unpaidInvoices
                .filter { invoice in
                    guard let dueDate = invoice.dueDate else { return false }
                    return calendar.isDate(dueDate, inSameDayAs: date)
                }
                .reduce(Decimal(0)) { $0 + $1.total }
            
            // Outflow: subscriptions due on this date
            let activeSubscriptions = try subscriptionsRepo.fetchActive()
            let outflow = activeSubscriptions
                .filter { subscription in
                    calendar.isDate(subscription.nextDueDate, inSameDayAs: date)
                }
                .reduce(Decimal(0)) { $0 + $1.amount }
            
            points.append(ForecastPoint(date: date, inflow: inflow, outflow: outflow))
        }
        
        return points
    }
}

