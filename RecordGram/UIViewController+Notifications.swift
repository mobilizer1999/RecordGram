//
//  UIViewController+Notifications.swift
//  RecordGram
//
//  Created by Nicolas Gonzalez on 4/10/18.
//  Copyright © 2018 Meridian Inc. All rights reserved.
//

import UIKit
import UserNotifications

extension UIViewController {
    
    func setupNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.sound, .alert, .badge]) { granted, error in
            if granted {
                print("Approval granted to send notifications")
            } else {
                print(error)
            }
        }
        
        UIApplication.shared.registerForRemoteNotifications()
    }
}
