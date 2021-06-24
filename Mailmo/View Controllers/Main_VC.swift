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
    var databaseHandler: DatabaseHandle?
    
    var welcomeText = String()

    var showStatusPopup = Bool()
    var iconText = String()
    var statusText = String()
    
    var showButtonHints = false
    var stopHistoryPulse = false
    var noOfEmails = Int()
    
    // Passed from SignIn_VC
    var userExists = Bool()
    var showWelcomePopup = Bool()
    var showTutorialView = Bool()
    var showPulsingButton = Bool()

    // MARK: - Outlet Variables
    @IBOutlet weak var welcomeIcon: UIImageView!
    
    @IBOutlet weak var newButton: UIButton!
    @IBOutlet weak var historyButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var bottomButtons: UIView!

    @IBOutlet weak var startHint: UIImageView!
    @IBOutlet weak var historyHint: UIImageView!
    @IBOutlet weak var settingsHint: UIImageView!
    @IBOutlet weak var newHint: UIImageView!
    
    @IBOutlet weak var tutorialView: UIView!
    @IBOutlet weak var startedButton: UIButton!

    // MARK: - Lazy Variables
    lazy var welcomeAnimation: AnimationView = {
        Utils.loadAnimation(fileName: "welcomeAnimation", loadingView: welcomeIcon)
    }()

    lazy var hud: JGProgressHUD = {
        let hud = JGProgressHUD(style: .extraLight)
        hud.interactionType = .blockAllTouches
        return hud
    }()

    // MARK: - View Controller Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
        
        checkIfSignInPersists()
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
        hudView(show: false, text: "")

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
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { [weak self] (_) in
            guard let strongSelf = self else { return }
            
            strongSelf.logOut(dueToError: false)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.pruneNegativeWidthConstraints()
        present(alert, animated: true, completion: nil)
    }

    @IBAction func pressedStarted(_ sender: Any) {
        bottomButtons.isUserInteractionEnabled = true
        tutorialViewPermission()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.tutorialPopup(show: false)
        }
    }

    // MARK: - Methods

    // Checks if user can stay signed in
    func checkIfSignInPersists() {
        
        if firebaseAuth.currentUser == nil {
            // If there is no user
            DispatchQueue.main.async {
                let navController = UINavigationController(rootViewController: SignIn_VC())
                navController.isNavigationBarHidden = true
                self.present(navController, animated: true, completion: nil)
            }
        } else {
            retrieveUserInfo()
        }
    }
    
    // Retrieve currentUserInfo
    func retrieveUserInfo() {
        // Start welcome animation
        welcomeAnimation.play(fromProgress: 0, toProgress: 1, loopMode: .loop, completion: nil)
        
        // Hide tutorial view + buttonHints
        showViews(show: false, views: [tutorialView, startHint, historyHint, settingsHint, newHint])
        
        // Get user's uid
        if let uid = firebaseAuth.currentUser?.uid {
    
            // Retrieve user snapshot info
            firebaseData.child("users/\(uid)").observeSingleEvent(of: .value) { [weak self] (snapshot) in
                guard let strongSelf = self else { return }

                // Guard if there is no user snapshot
                guard let userSnapshot = snapshot.value as? [String: Any] else { return }

                // Save userSnapshot to currentUserInfo
                Utils.currentUserInfo = CurrentUser(uid: uid, dictionary: userSnapshot)

                // Retrieve user's name for welcomeText
                if let user = Utils.currentUserInfo {
                    if strongSelf.userExists {
                        strongSelf.welcomeTextPicker(checkName: user.name,
                                               genericText: "Welcome back!",
                                               nameText: "Welcome back, \(user.name)!")
                    } else {
                        strongSelf.welcomeTextPicker(checkName: user.name,
                                               genericText: "Welcome to Mailmo!",
                                               nameText: "Welcome to Mailmo, \(user.name)!")
                    }
                }

                strongSelf.tutorialViewPermission()

            } withCancel: { (error) in
                print("error: \(error)")
                self.logOut(dueToError: true)
                fatalError("Error has occurred")
            }
            
        }
     
    }
    
    // Determine whether to show tutorialView
    func tutorialViewPermission() {
        
        DispatchQueue.main.async {

            if self.showTutorialView {
                self.welcomeAnimation.pause()
                self.bottomButtons.isUserInteractionEnabled = false

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.tutorialPopup(show: true)
                    self.showTutorialView = false
                }
            } else {
                self.welcomeAnimation.play(fromProgress: 0, toProgress: 1, loopMode: .loop, completion: nil)
                self.showStatusOrWelcomePopup()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.buttonHintPermissions()
                }
            }
            
        }
    }
    
    func tutorialPopup(show: Bool) {
        if show {
            UIView.animate(withDuration: 1, delay: 0,
                           options: .curveEaseIn,
                           animations: {
                            self.tutorialView.alpha = 1.0
                           }, completion: nil)
        } else {
            UIView.animate(withDuration: 1, delay: 0,
                           options: .curveEaseOut, animations: {
               // Hide tutorial view
               self.tutorialView.alpha = 0.0
            }, completion: nil)
        }
    }
    
    func showStatusOrWelcomePopup() {
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
    
    // Determine whether to show buttonHints
    func buttonHintPermissions() {
        
        // Determine which buttonHints to show based on noOfEmails
        if let uid = firebaseAuth.currentUser?.uid {
            
            databaseHandler = firebaseData.child("posts/\(uid)").observe(.value, with: { [weak self] (snapshot) in
                guard let strongSelf = self else { return }
                        
                // Find noOfEmails
                strongSelf.noOfEmails = Int(snapshot.childrenCount)
                
                if strongSelf.noOfEmails == 0 && strongSelf.showTutorialView == false {
                    // Show pulsing newButton + buttonHints (noOfEmails = 0)
                    UIView.animate(withDuration: 0.6) {
                        strongSelf.showPulsingButton(button: strongSelf.newButton, color: #colorLiteral(red: 0.9423340559, green: 0.3914486766, blue: 0.2496597767, alpha: 1))
                        
                        strongSelf.showViews(show: true, views: [strongSelf.startHint, strongSelf.historyHint, strongSelf.settingsHint])
                    }
                } else if strongSelf.noOfEmails == 1 && strongSelf.stopHistoryPulse == false {
                    // Show pulsing historyButton + historyInfo buttonHint (noOfEmails = 1)
                    UIView.animate(withDuration: 0.6) {
                        strongSelf.showPulsingButton(button: strongSelf.historyButton, color: #colorLiteral(red: 0.9080473781, green: 0.3728664517, blue: 0.6483925581, alpha: 1))

                        strongSelf.showViews(show: true, views: [strongSelf.newHint, strongSelf.historyHint, strongSelf.settingsHint])
                    }
                }
                
            })
        }
    }
    
    func showViews(show: Bool, views: [UIView]) {
        if show {
            for view in views {
                view.alpha = 1.0
            }
        } else {
            for view in views {
                view.alpha = 0.0
            }
        }
    }
    
    func showPulsingButton(button: UIButton, color: CGColor) {
        let pulse = PulseAnimation(numberOfPulses: 10,
                                   radius: button.bounds.width / 1.75,
                                   position: CGPoint(x: self.historyButton.bounds.width / 2,
                                                     y: self.historyButton.bounds.height / 2))
        pulse.animationDuration = 2.0
        pulse.backgroundColor = color
        button.layer.insertSublayer(pulse, below: button.layer)
    }

    func welcomeTextPicker(checkName: String, genericText: String, nameText: String) {
        if checkName == Utils.n_a || checkName == "" {
            self.welcomeText = genericText
        } else {
            self.welcomeText = nameText
        }
    }

    func statusPopup() {
        Utils.popupFormatter(body: statusText, iconText: iconText)
    }

    func welcomePopup() {
        let iconText = ["😎", "👋🏽", "🤙🏽", "🤗"].randomElement()!
        Utils.popupFormatter(body: welcomeText, iconText: iconText)
    }

    func hudView(show: Bool, text: String) {
        if show {
            hud.textLabel.text = text
            hud.detailTextLabel.text = nil
            hud.show(in: view, animated: true)
        } else {
            hud.dismiss(afterDelay: 1.5, animated: true)
        }
    }

    func logOut(dueToError: Bool) {
        if dueToError {
            hudView(show: true, text: "Logging out due to error...")
        } else {
            // Show HUD
            hudView(show: true, text: "Logging out...")
        }

        // Sign user out of Google
        GIDSignIn.sharedInstance()?.signOut()

        // Sign user out of Firebase
        do {
            try firebaseAuth.signOut()
            transitionToSignIn()
        } catch {
            Utils.dismissHud(Utils.hud, text: "Error", detailText: error.localizedDescription, delay: 1)
        }
        print("Logged out")
    }

}
