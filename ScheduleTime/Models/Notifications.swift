//
//  Notifications.swift
//  ScheduleTime
//
//  Created by Vaishant Makan on 17/07/20.
//  Copyright © 2020 Vaishant Makan. All rights reserved.
//

import Foundation
import UserNotifications

class Notifications: NSObject, UNUserNotificationCenterDelegate {
    
    let notificationCenter = UNUserNotificationCenter.current()
    
    func notificationRequest() {
        
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        
        notificationCenter.requestAuthorization(options: options) {
            (didAllow, error) in
            if !didAllow {
                print("User has declined notifications")
            }
            // Enable or disable features based on authorization
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
        
    }
    
    func scheduleNotification(from component: DateComponents, cell: ScheduleTableViewCell) {
        
        let content = UNMutableNotificationContent()
        
        content.title = "\(cell.activityBodyLabel.text ?? "New Activity") - \(cell.descriptionLabel.text ?? "")"
        content.body = "Your new activity starts now !"
        content.sound = UNNotificationSound.default
        content.badge = 1
        
        let dateComponent = component
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponent, repeats: false)
        
        let identifier = cell.timeLabel.text ?? ""    //"Local Notification"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        notificationCenter.add(request) { (error) in
            if let error = error {
                print("Error \(error.localizedDescription)")
            }
        }
        
    }
    
    func cancelNotification(from component: DateComponents, cell: ScheduleTableViewCell) {
        
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [cell.timeLabel.text!])
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [cell.timeLabel.text!])
    }
    
    //if a person edits an already existing cell...
    func cancelIfEdited(from componet: DateComponents, prevStartingTime: String, prevEndingTime: String) {
        
        let timeLabel = "\(prevStartingTime) - \(prevEndingTime)"
        
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [timeLabel])
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [timeLabel])
        
    }
}

