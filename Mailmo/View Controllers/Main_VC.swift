//
//  Main_VC.swift
//  Mailmo App
//
//  Created by Nadia Siddiqah on 3/17/21.
//

import UIKit
import Lottie
import GoogleSignIn
import AuthenticationServices
import Firebase
import JGProgressHUD
import SwiftMessages

class Main_VC: UIViewController {
    
    // MARK: - Variables
    let firebaseAuth = Auth.auth()
    let firebaseData = Database.database().reference()
    
    var userExists = Bool()
    var showWelcomePopup = Bool()
    var welcomeText = String()
    
    var showStatusPopup = Bool()
    var iconText = String()
    var statusText = String()
    
    // MARK: - Outlet Variables
    @IBOutlet weak var welcomeIcon: UIImageView!
    
    // MARK: - Lazy Variables
    lazy var welcomeAnimation: AnimationView = {
        loadAnimation(fileName: "welcomeAnimation", loadingView: welcomeIcon)
    }()
    
    lazy var hud: JGProgressHUD = {
        let hud = JGProgressHUD(style: .extraLight)
        hud.interactionType = .blockAllTouches
        return hud
    }()

    // MARK: - View Controller Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkIfUserIsSignedIn()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
        welcomeAnimation.play(fromProgress: 0, toProgress: 1, loopMode: .loop, completion: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        welcomeAnimation.pause()
    }
    
    // MARK: - Navigation Methods
    @IBAction func unwindFromEditToMain(_ unwindSegue: UIStoryboardSegue) {
    }
    
    @IBAction func unwindFromHistoryToMain(_ unwindSegue: UIStoryboardSegue) {
    }
    
    @IBAction func unwindFromNewToMain(_ unwindSegue: UIStoryboardSegue) {
    }
    
    @IBAction func unwindFromSettingsToMain(_ unwindSegue: UIStoryboardSegue) {
    }
    
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
        let alert = UIAlertController(title: nil,
                                      message: "Are you sure you want to log out?",
                                      preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { (_) in
            self.logOut()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.pruneNegativeWidthConstraints()
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Methods
    // Checks if user can stay signed in
    func checkIfUserIsSignedIn() {
        if firebaseAuth.currentUser == nil {
            // If there is no user
            DispatchQueue.main.async {
                let navController = UINavigationController(rootViewController: SignIn_VC())
                navController.isNavigationBarHidden = true
                self.present(navController, animated: true, completion: nil)
            }
        } else {
            setupView()
        }
    }
    
    func setupView() {
        welcomeAnimation.play(fromProgress: 0, toProgress: 1, loopMode: .loop, completion: nil)
        
        DispatchQueue.main.async {
            self.retrieveUserInfo()
            
            if self.showStatusPopup {
                self.showStatusPopup = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    self.statusPopup()
                }
            }
            
            if self.showWelcomePopup {
                self.showWelcomePopup = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    self.welcomePopup()
                }
            }
        }

    }
    
    func retrieveUserInfo() {
        if let uid = self.firebaseAuth.currentUser?.uid {
            print("retrieveUser: \(uid)")
            // Retrieve userSnapshot
            self.firebaseData.child("users/\(uid)").observeSingleEvent(of: .value) { (snapshot) in
                guard let userSnapshot = snapshot.value as? [String: Any] else {
                    print("no snapshot")
                    return
                }
                print(userSnapshot)

                // Save userSnapshot to currentUserInfo
                currentUserInfo = CurrentUser(uid: uid, dictionary: userSnapshot)

                // Retrieve user's name for welcomeText
                if let user = currentUserInfo {
                    print(user.name)
                    if self.userExists {
                        self.welcomeTextPicker(checkName: user.name,
                                               genericText: "Welcome back!",
                                               nameText: "Welcome back, \(user.name)!")
                    } else {
                        self.welcomeTextPicker(checkName: user.name,
                                               genericText: "Welcome to Mailmo!",
                                               nameText: "Welcome to Mailmo, \(user.name)!")
                    }
                }
                
            } withCancel: { (error) in
                print(error)
            }
        }
    }
    
    func welcomeTextPicker(checkName: String, genericText: String, nameText: String) {
        if checkName == n_a || checkName == "" {
            self.welcomeText = genericText
        } else {
            self.welcomeText = nameText
        }
    }
    
    func statusPopup() {
        popupFormatter(body: statusText, iconText: iconText)
    }
    
    func welcomePopup() {
        let iconText = ["😎", "👋🏽", "🤙🏽", "🤗"].randomElement()!
        popupFormatter(body: welcomeText, iconText: iconText)
    }
    
    func hudView(show: Bool) {
        if show {
            hud.textLabel.text = "Logging out..."
            hud.detailTextLabel.text = nil
            hud.show(in: view, animated: true)
        } else {
            hud.dismiss(afterDelay: 1.5, animated: true)
        }
    }
    
    func logOut() {
        // Show HUD
        hudView(show: true)
        
        // Sign user out of Google
        GIDSignIn.sharedInstance()?.signOut()
       
        // Sign user out of Firebase
        do {
            try firebaseAuth.signOut()
            transitionToSignIn()
        } catch {
            dismissHud(hud, text: "Error", detailText: error.localizedDescription, delay: 1)
        }
        print("Logged out")
    }
    
}
