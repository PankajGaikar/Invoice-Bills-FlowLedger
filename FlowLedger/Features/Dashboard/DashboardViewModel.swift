//
//  DashboardViewModel.swift
//  FlowLedger
//
//  Created by Pankaj Gaikar on 02/11/25.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var paidIncome: Decimal = 0
    @Published var billsDue: Decimal = 0
    @Published var net: Decimal = 0
    @Published var forecast: [DashboardRepository.ForecastPoint] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let repository: DashboardRepository
    
    init(modelContext: ModelContext) {
        self.repository = DashboardRepository(modelContext: modelContext)
    }
    
    func loadMetrics() {
        isLoading = true
        errorMessage = nil
        
        do {
            let metrics = try repository.getThisMonthMetrics()
            paidIncome = metrics.paidIncome
            billsDue = metrics.billsDue
            net = metrics.net
            
            forecast = try repository.getNext30DaysForecast()
        } catch {
            errorMessage = "Failed to load metrics: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

