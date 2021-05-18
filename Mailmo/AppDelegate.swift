//
//  AppDelegate.swift
//  Mailmo
//
//  Created by Nadia Siddiqah on 3/19/21.
//

import UIKit
import IQKeyboardManagerSwift
import GoogleSignIn
import Firebase

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: - Variables
    var window: UIWindow?

    // MARK: - App Delegate Methods
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Show keyboard below text field
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.keyboardDistanceFromTextField = 55
        IQKeyboardManager.shared.enableAutoToolbar = false
        
        // Configure Firebase for Real-time Database backend
        FirebaseApp.configure()
        
        // Assign root view controller
        window = UIWindow()
        window?.makeKeyAndVisible()
        let navController = UINavigationController(rootViewController: Main_VC())
        navController.isNavigationBarHidden = true
        window?.rootViewController = navController
        
        // Configure Google sign in
        GIDSignIn.sharedInstance()?.clientID = FirebaseApp.app()?.options.clientID
        
        return true
    }
    
    // Allows app to handle opening GIDSignIn URL
    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        // Open Google Sign In Web Link
        return GIDSignIn.sharedInstance().handle(url)
    }
    
    // MARK: - UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }

}
