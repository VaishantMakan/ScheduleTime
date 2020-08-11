//
//  AppDelegate.swift
//  ScheduleTime
//
//  Created by Vaishant Makan on 09/07/20.
//  Copyright © 2020 Vaishant Makan. All rights reserved.
//

import UIKit
import RealmSwift
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    //notification
    let notifications = Notifications()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        //realm location
        //print(Realm.Configuration.defaultConfiguration.fileURL)
        //creating new realm
        do {
            _ = try Realm()
            
        } catch {
            print("Error initialising new realm, \(error)")
        }
        
        //notifications
        notifications.notificationCenter.delegate = notifications
        notifications.notificationRequest()
        
        //this is done in scene delegate
//        UIApplication.shared.applicationIconBadgeNumber = 0
        
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    
}
