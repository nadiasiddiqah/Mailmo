//
//  AppDelegate.swift
//  Mailmo
//
//  Created by Nadia Siddiqah on 3/19/21.
//

import UIKit
import GoogleSignIn
import Firebase

@main
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {

    // MARK: - Variables
    var window: UIWindow?

    // MARK: - App Delegate Methods
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Configure Firebase for Real-time Database backend
        FirebaseApp.configure()
        
        // Configure sign in with Google
        GIDSignIn.sharedInstance()?.clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance()?.delegate = self
        
        return true
    }
    
    // MARK: - Google Sign-in Delegate Methods
    
    // Allows app to handle GIDSignIn
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!,
              withError error: Error!) {
        
        // Google sign in
        if let error = error {
            // Check for google sign in error
            print(error.localizedDescription)
            print("Error: Google log-in unsuccessful")
            return
        }
        
        // Check for user's googleAuth and googleCredential
        guard let googleAuth = user.authentication else { return }
        let googleCredential = GoogleAuthProvider.credential(withIDToken: googleAuth.idToken,
                                                             accessToken: googleAuth.accessToken)
        print("Google log-in successful")
        
        // Firebase sign in with googleCredential
        let firebaseAuth = Auth.auth()
        let firebaseData = Database.database().reference()
        
        firebaseAuth.signIn(with: googleCredential) { (result, error) in
            // Check for firebase sign in error
            if let error = error {
                print("Error: Failed to create a Firebase user with Google", error)
                return
            }
            
            // Check for user's uid
            guard let uid = result?.user.uid else { return }
            print("Created Firebase user with Google")
            let name = user.profile.name ?? "no name"
            let email = user.profile.email ?? "no email"
            
            // Save user in firebase database
            firebaseData.child("users/\(uid)").setValue(["name": name,
                                                         "email": email])
        }
        
        // Allows app to handle GIDDiscconection
        func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!,
                  withError error: Error!) {
            print("User has disconnected")
        }
        
        // Allows app to handle opening GIDSignIn URL
        func application(_ app: UIApplication, open url: URL,
                         options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
            return GIDSignIn.sharedInstance().handle(url)
        }
        
        // MARK: - UISceneSession Lifecycle
        
        func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession,
                         options: UIScene.ConnectionOptions) -> UISceneConfiguration {
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
}

