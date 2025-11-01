//
//  AnalyticsService.swift
//  FlowLedger
//
//  Created by Pankaj Gaikar on 02/11/25.
//

import Foundation

@MainActor
class AnalyticsService {
    static let shared = AnalyticsService()
    
    private init() {}
    
    func logEvent(_ event: String, parameters: [String: Any]? = nil) {
        // TODO: Integrate Firebase Analytics
        // For now, just log to console
        print("[Analytics] Event: \(event), Parameters: \(parameters ?? [:])")
    }
    
    func setUserProperty(_ value: String, forName name: String) {
        // TODO: Integrate Firebase Analytics
        print("[Analytics] User Property: \(name) = \(value)")
    }
    
    func logNonFatalError(_ error: Error, context: String) {
        // TODO: Integrate Crashlytics
        print("[Analytics] Non-fatal error in \(context): \(error.localizedDescription)")
    }
    
    // Convenience methods for common events
    func logAppLaunch(source: String) {
        logEvent("app_launch", parameters: ["source": source])
    }
    
    func logDashboardViewed(range: String) {
        logEvent("dashboard_viewed", parameters: ["range": range])
    }
    
    func logInvoiceCreated(lineCount: Int, hasTax: Bool, subtotal: Decimal) {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let subtotalString = formatter.string(from: subtotal as NSDecimalNumber) ?? "0"
        logEvent("invoice_created", parameters: [
            "line_count": lineCount,
            "has_tax": hasTax,
            "subtotal": subtotalString
        ])
    }
    
    func logInvoiceStatusChanged(from: String, to: String) {
        logEvent("invoice_status_changed", parameters: [
            "from": from,
            "to": to
        ])
    }
    
    func logSubscriptionAdded(cadence: String, category: String?) {
        var params: [String: Any] = ["cadence": cadence]
        if let category = category {
            params["category"] = category
        }
        logEvent("subscription_added", parameters: params)
    }
    
    func logBillMarkedPaid(amount: Decimal) {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let amountString = formatter.string(from: amount as NSDecimalNumber) ?? "0"
        logEvent("bill_marked_paid", parameters: ["amount": amountString])
    }
}

