//
//  NotificationService.swift
//  FlowLedger
//
//  Created by Pankaj Gaikar on 02/11/25.
//

import Foundation
import UserNotifications
import SwiftData

@MainActor
class NotificationService {
    static let shared = NotificationService()
    
    private init() {}
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("Failed to request notification authorization: \(error)")
            return false
        }
    }
    
    func scheduleReminder(for subscription: Subscription, modelContext: ModelContext) async {
        guard !subscription.isPaused else { return }
        
        let calendar = Calendar.current
        let reminderDate = calendar.date(byAdding: .day, value: -subscription.reminderDaysBefore, to: subscription.nextDueDate)
        guard let reminderDate = reminderDate, reminderDate > Date() else { return }
        
        // Get reminder time from settings (default 9 AM)
        let settingsStore = SettingsStore(modelContext: modelContext)
        let settings = try? settingsStore.getSettings()
        let reminderTime = settings?.reminderTime ?? calendar.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        
        let reminderTimeComponents = calendar.dateComponents([.hour, .minute], from: reminderTime)
        var reminderDateComponents = calendar.dateComponents([.year, .month, .day], from: reminderDate)
        reminderDateComponents.hour = reminderTimeComponents.hour
        reminderDateComponents.minute = reminderTimeComponents.minute
        
        guard let finalReminderDate = calendar.date(from: reminderDateComponents) else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Bill Due Soon"
        content.body = "\(subscription.name) is due in \(subscription.reminderDaysBefore) days"
        content.sound = .default
        content.userInfo = ["subscriptionId": subscription.id.uuidString]
        
        let triggerDate = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: finalReminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let identifier = "subscription-\(subscription.id.uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            
            // Save reminder to database
            let reminder = Reminder(
                subscription: subscription,
                scheduledDate: finalReminderDate,
                notificationId: identifier
            )
            modelContext.insert(reminder)
            try modelContext.save()
        } catch {
            print("Failed to schedule notification: \(error)")
            AnalyticsService.shared.logNonFatalError(error, context: "notification_schedule")
        }
    }
    
    func snoozeReminder(_ reminder: Reminder, modelContext: ModelContext) async {
        guard let subscription = reminder.subscription else { return }
        
        // Cancel existing notification
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminder.notificationId])
        
        // Schedule for 1 day later
        let newDate = Calendar.current.date(byAdding: .day, value: 1, to: reminder.scheduledDate) ?? reminder.scheduledDate
        
        let content = UNMutableNotificationContent()
        content.title = "Bill Due Soon"
        content.body = "\(subscription.name) is due soon"
        content.sound = .default
        content.userInfo = ["subscriptionId": subscription.id.uuidString]
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: newDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let identifier = reminder.notificationId
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            reminder.scheduledDate = newDate
            reminder.isSnoozed = true
            try modelContext.save()
        } catch {
            print("Failed to snooze notification: \(error)")
        }
    }
    
    func cancelReminder(_ reminder: Reminder) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminder.notificationId])
    }
    
    func rescheduleAllReminders(modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Subscription>(
            predicate: #Predicate { $0.isPaused == false }
        )
        
        do {
            let subscriptions = try modelContext.fetch(descriptor)
            for subscription in subscriptions {
                await scheduleReminder(for: subscription, modelContext: modelContext)
            }
        } catch {
            print("Failed to reschedule reminders: \(error)")
        }
    }
}

