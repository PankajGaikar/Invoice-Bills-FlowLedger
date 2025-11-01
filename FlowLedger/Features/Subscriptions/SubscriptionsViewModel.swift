//
//  SubscriptionsViewModel.swift
//  FlowLedger
//
//  Created by Pankaj Gaikar on 02/11/25.
//

import Foundation
import Combine
import SwiftData
import SwiftUI

@MainActor
class SubscriptionsViewModel: ObservableObject {
    @Published var subscriptions: [Subscription] = []
    @Published var selectedCategory: String? = nil
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let repository: SubscriptionsRepository
    
    init(modelContext: ModelContext) {
        self.repository = SubscriptionsRepository(modelContext: modelContext)
    }
    
    var categories: [String] {
        let allCategories = subscriptions.compactMap { $0.category }
        return Array(Set(allCategories)).sorted()
    }
    
    func loadSubscriptions() {
        isLoading = true
        errorMessage = nil
        
        do {
            if let category = selectedCategory {
                subscriptions = try repository.fetchByCategory(category)
            } else {
                subscriptions = try repository.fetchActive()
            }
            
            if !searchText.isEmpty {
                subscriptions = subscriptions.filter { subscription in
                    subscription.name.localizedCaseInsensitiveContains(searchText)
                }
            }
        } catch {
            errorMessage = "Failed to load subscriptions: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func deleteSubscription(_ subscription: Subscription) {
        do {
            try repository.delete(subscription)
            loadSubscriptions()
        } catch {
            errorMessage = "Failed to delete subscription: \(error.localizedDescription)"
        }
    }
    
    func markAsPaid(_ subscription: Subscription) {
        do {
            try repository.markAsPaid(subscription)
            loadSubscriptions()
        } catch {
            errorMessage = "Failed to mark as paid: \(error.localizedDescription)"
        }
    }
}

