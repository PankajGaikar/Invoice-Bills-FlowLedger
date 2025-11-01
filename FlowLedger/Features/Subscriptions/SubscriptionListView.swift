//
//  SubscriptionListView.swift
//  FlowLedger
//
//  Created by Pankaj Gaikar on 02/11/25.
//

import SwiftUI
import SwiftData

struct SubscriptionListView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: SubscriptionsViewModel
    @State private var selectedSubscription: Subscription?
    @State private var showingNewSubscription = false
    
    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: SubscriptionsViewModel(modelContext: modelContext))
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.subscriptions.isEmpty && !viewModel.isLoading {
                    EmptyStateView(
                        title: "No bills yet",
                        message: "No bills yet",
                        systemImage: "calendar.badge.clock",
                        actionTitle: "Add a Bill"
                    ) {
                        showingNewSubscription = true
                    }
                } else {
                    List {
                        ForEach(viewModel.subscriptions) { subscription in
                            NavigationLink(value: subscription) {
                                SubscriptionRowView(subscription: subscription)
                            }
                            .swipeActions(edge: .trailing) {
                                Button {
                                    viewModel.markAsPaid(subscription)
                                } label: {
                                    Label("Mark Paid", systemImage: "checkmark.circle.fill")
                                }
                                .tint(Theme.success)
                            }
                        }
                        .onDelete(perform: deleteSubscriptions)
                    }
                    .searchable(text: $viewModel.searchText, prompt: "Search bills")
                    .onChange(of: viewModel.searchText) { _, _ in
                        viewModel.loadSubscriptions()
                    }
                    
                    if !viewModel.categories.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Theme.spacing) {
                                Button {
                                    viewModel.selectedCategory = nil
                                    viewModel.loadSubscriptions()
                                } label: {
                                    Text("All")
                                        .padding(.horizontal, Theme.spacing2)
                                        .padding(.vertical, Theme.spacing)
                                        .background(viewModel.selectedCategory == nil ? Theme.accent : Theme.surfaceLight)
                                        .foregroundColor(viewModel.selectedCategory == nil ? .white : .primary)
                                        .cornerRadius(8)
                                }
                                
                                ForEach(viewModel.categories, id: \.self) { category in
                                    Button {
                                        viewModel.selectedCategory = category
                                        viewModel.loadSubscriptions()
                                    } label: {
                                        Text(category)
                                            .padding(.horizontal, Theme.spacing2)
                                            .padding(.vertical, Theme.spacing)
                                            .background(viewModel.selectedCategory == category ? Theme.accent : Theme.surfaceLight)
                                            .foregroundColor(viewModel.selectedCategory == category ? .white : .primary)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                            .padding(.horizontal, Theme.spacing2)
                        }
                        .padding(.vertical, Theme.spacing)
                    }
                }
            }
            .navigationTitle("Subscriptions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingNewSubscription = true
                    } label: {
                        Label("Add Bill", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewSubscription) {
                SubscriptionDetailView(modelContext: modelContext, subscription: nil)
            }
            .navigationDestination(for: Subscription.self) { subscription in
                SubscriptionDetailView(modelContext: modelContext, subscription: subscription)
            }
            .onAppear {
                viewModel.loadSubscriptions()
            }
        }
    }
    
    private func deleteSubscriptions(offsets: IndexSet) {
        for index in offsets {
            viewModel.deleteSubscription(viewModel.subscriptions[index])
        }
    }
}

struct SubscriptionRowView: View {
    let subscription: Subscription
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name)
                    .font(Theme.bodyFont(size: 16, weight: .semibold))
                
                HStack(spacing: 8) {
                    Text(cadenceText)
                        .font(Theme.bodyFont(size: 12))
                        .foregroundColor(.secondary)
                    
                    if let category = subscription.category {
                        Text("• \(category)")
                            .font(Theme.bodyFont(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                CurrencyText(amount: subscription.amount, font: Theme.monospacedFont(size: 16))
                
                Text("Due \(nextDueText)")
                    .font(Theme.bodyFont(size: 12))
                    .foregroundColor(dueColor)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var cadenceText: String {
        switch subscription.subscriptionCadence {
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .yearly: return "Yearly"
        }
    }
    
    private var nextDueText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: subscription.nextDueDate, relativeTo: Date())
    }
    
    private var dueColor: Color {
        let daysUntilDue = Calendar.current.dateComponents([.day], from: Date(), to: subscription.nextDueDate).day ?? 0
        if daysUntilDue < 0 {
            return Theme.danger
        } else if daysUntilDue <= 3 {
            return Theme.warning
        } else {
            return .secondary
        }
    }
}

#Preview {
    let schema = Schema([Subscription.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    return SubscriptionListView(modelContext: ModelContext(container))
}

