//
//  MainTabView.swift
//  FlowLedger
//
//  Created by Pankaj Gaikar on 02/11/25.
//

import SwiftUI
import SwiftData

enum NavigationItem: String, CaseIterable {
    case dashboard = "Dashboard"
    case invoices = "Invoices"
    case subscriptions = "Subscriptions"
    case settings = "Settings"
    
    var icon: String {
        switch self {
        case .dashboard: return "chart.line.uptrend.xyaxis"
        case .invoices: return "doc.text"
        case .subscriptions: return "calendar.badge.clock"
        case .settings: return "gear"
        }
    }
}

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedItem: NavigationItem = .dashboard
    
    var body: some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .pad {
                // iPad: Sidebar navigation
                NavigationSplitView {
                    sidebarView
                } detail: {
                    detailView
                }
            } else {
                // iPhone: Tab bar
                TabView(selection: $selectedItem) {
                    DashboardView(modelContext: modelContext)
                        .tabItem {
                            Label("Dashboard", systemImage: NavigationItem.dashboard.icon)
                        }
                        .tag(NavigationItem.dashboard)
                    
                    InvoiceListView(modelContext: modelContext)
                        .tabItem {
                            Label("Invoices", systemImage: NavigationItem.invoices.icon)
                        }
                        .tag(NavigationItem.invoices)
                    
                    SubscriptionListView(modelContext: modelContext)
                        .tabItem {
                            Label("Bills", systemImage: NavigationItem.subscriptions.icon)
                        }
                        .tag(NavigationItem.subscriptions)
                    
                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: NavigationItem.settings.icon)
                        }
                        .tag(NavigationItem.settings)
                }
            }
        }
        .onAppear {
            // Request notification permissions on launch
            Task {
                _ = await NotificationService.shared.requestAuthorization()
            }
        }
    }
    
    @ViewBuilder
    private var sidebarView: some View {
        List(selection: $selectedItem) {
            ForEach(NavigationItem.allCases, id: \.self) { item in
                Label(item.rawValue, systemImage: item.icon)
                    .tag(item)
            }
        }
        .navigationTitle("FlowLedger")
    }
    
    @ViewBuilder
    private var detailView: some View {
        Group {
            switch selectedItem {
            case .dashboard:
                DashboardView(modelContext: modelContext)
            case .invoices:
                InvoiceListView(modelContext: modelContext)
            case .subscriptions:
                SubscriptionListView(modelContext: modelContext)
            case .settings:
                SettingsView()
            }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Invoice.self, Subscription.self, AppSettings.self], inMemory: true)
}

