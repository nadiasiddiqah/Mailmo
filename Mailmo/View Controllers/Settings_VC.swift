//
//  Settings_VC.swift
//  Mailmo
//
//  Created by Nadia Siddiqah on 3/24/21.
//

import UIKit
import GoogleSignIn
import Firebase
import JGProgressHUD

class Settings_VC: UIViewController {
    
    // MARK: - Variables
    lazy var hud: JGProgressHUD = {
        let hud = JGProgressHUD(style: .extraLight)
        hud.interactionType = .blockAllTouches
        return hud
    }()
    
    // MARK: - Outlets
    
    // MARK: - View Methods
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Navigation
    func transitionToSignIn() {
        
        // Hide HUD
        hudView(show: false)
        
        // Update root view controller to SignInVC (when user signs out)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let signInVC = self.storyboard?.instantiateViewController(withIdentifier: "SignInVC") as? SignIn_VC
            self.view.window?.rootViewController = signInVC
            self.view.window?.makeKeyAndVisible()
        }
    }
    
    // MARK: - Action Methods
    @IBAction func pressedLogOut(_ sender: Any) {
        // Show HUD
        hudView(show: true)
        
        // Sign user out of Google
        GIDSignIn.sharedInstance()?.signOut()
        
        // Sign user out of Firebase
        do {
            try Auth.auth().signOut()
            transitionToSignIn()
        } catch {
            dismissHud(hud, text: "Error", detailText: error.localizedDescription, delay: 1)
        }
        print("Signed out")
    }
    
    // MARK: - Methods
    func hudView(show: Bool) {
        if show {
            hud.textLabel.text = "Logging out..."
            hud.detailTextLabel.text = nil
            hud.show(in: view, animated: true)
        } else {
            hud.dismiss(afterDelay: 1.5, animated: true)
        }
    }
    
}
