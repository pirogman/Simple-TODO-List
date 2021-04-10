//
//  AppDelegate.swift
//  Simple TODO List
//
//  Created by Alex Pirog on 01.04.2021.
//

import UIKit
import CoreData

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
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

    // MARK: - CoreData Container

    lazy var persistentContainer: PersistentContainer = {
        let container = PersistentContainer(name: "Simple_TODO_List")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if error != nil {
                fatalError(" ! Error loading core data: \(error!)")
            }
        })
        return container
    }()

}


extension AppDelegate {
    
    static var current: AppDelegate? {
        return UIApplication.shared.delegate as? AppDelegate
    }
    
}
