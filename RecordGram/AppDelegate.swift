//
//  AppDelegate.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/5/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import AlamofireNetworkActivityIndicator
import AlamofireNetworkActivityLogger
import Fabric
import Crashlytics
import TwitterKit
import Firebase
import Kingfisher

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var mainTab: MainTabBarController? = nil
    var deviceToken = ""

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
#if DEBUG
        NetworkActivityLogger.shared.level = .debug
        NetworkActivityLogger.shared.startLogging()
#endif

        Fabric.with([Crashlytics.self])
        
//        ImageCache.default.clearDiskCache()

        // Status Bar
        UIApplication.shared.statusBarStyle = .lightContent

        // NavigationBar Setup
        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().barTintColor = UIColor.rgb(red: 57, green: 4, blue: 54, alpha: 1)
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().clipsToBounds = false

        if let font = UIFont(name: "BebasNeueRG-Regular", size: 22) {
            UINavigationBar.appearance().titleTextAttributes = [NSAttributedStringKey.font: font, NSAttributedStringKey.foregroundColor: UIColor.white]
        }

        if let font = UIFont(name: "BebasNeueRG-Regular", size: 17) {
            UISegmentedControl.appearance().setTitleTextAttributes([NSAttributedStringKey.font: font], for: .normal)
        }

        // TabBar Setup
        UITabBar.appearance().backgroundColor = UIColor.rgb(red: 57, green: 4, blue: 54, alpha: 1)
        UITabBar.appearance().barTintColor = UIColor.rgb(red: 57, green: 4, blue: 54, alpha: 1)
        UITabBar.appearance().tintColor = .white

        NetworkActivityIndicatorManager.shared.isEnabled = true

        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)

        FirebaseApp.configure()

        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        self.deviceToken = deviceToken.map {
            String(format: "%02.2hhx", $0)
        }.joined()
        if let _ = UserDefaults.standard.string(forKey: kJWTKey) {
            DeviceClient.shared.attach()
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Application failed to register for remote notifications!")
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

