//
//  SignIn_VC.swift
//  Mailmo App
//
//  Created by Nadia Siddiqah on 3/16/21.
//

import UIKit
import Lottie
import GoogleSignIn
import Firebase
import JGProgressHUD
import SwiftMessages

class SignIn_VC: UIViewController {
    
    // MARK: - Variables
    let firebaseAuth = Auth.auth()
    let firebaseData = Database.database().reference()
    var authHandler: AuthStateDidChangeListenerHandle?
    var databaseHandler: DatabaseHandle?
    
    var email = String()
    var pass = String()
    var userExists = false
    
    // MARK: - Outlet Variables
    @IBOutlet weak var mailmoIcon: UIImageView!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    
    // MARK: - Enums + Lazy Variables
    enum MailmoAnimationFrames: CGFloat {
        case start = 5
        case narrow = 15
        case firing = 25
    }
    
    lazy var mailmoAnimation: AnimationView = {
        loadAnimation(fileName: "mailmoIconAnimation", loadingView: mailmoIcon)
    }()
    
    // MARK: - View Controller Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Listens for changes in auth status
        authStateListener()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        mailmoAnimation.pause()
    }
    
    // MARK: - Navigation
    func transitionToMain() {
        
        // Dismiss HUD
        hud.dismiss(animated: true)
        dismiss(animated: true, completion: nil)
        
        // Set new rootVC as MainVC (when user logs in)
        let mainVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "MainVC") as! Main_VC
        mainVC.userExists = userExists
        mainVC.showWelcomePopup = true
        self.view.window?.rootViewController = mainVC
        self.view.window?.makeKeyAndVisible()
    }
    
    // MARK: - Action Methods
    @IBAction func logInWithEmail(_ sender: Any) {
        
        // Validate Text Fields
        let errorMessage = validateFields()
        
        if errorMessage != nil {
            // Something wrong in the fields, show error message
            errorHandler(errorMessage!, isHidden: false)
        } else {
            // No errors in fields
            errorHandler("", isHidden: true)
            
            // Show HUD view
            hudView(show: true, text: "Logging in...")
    
            // Log in User
            firebaseAuth.signIn(withEmail: email, password: pass) { (result, error) in
                
                if error != nil {
                    // Firebase sign in error
                    dismissHud(hud, text: "Error", detailText: "Failed to create new user", delay: 0.5)
                } else {
                    // Sign in successful
                    self.errorHandler("", isHidden: true)
                    self.userExists = true
                    
                    // Transition to main
                    DispatchQueue.main.async {
                        self.transitionToMain()
                    }
                }
                
            }
            
        }
        
    }
    
    @IBAction func logInWithApple(_ sender: Any) {
    }
    
    @IBAction func logInWithGoogle(_ sender: Any) {
        // Show HUD view
        hudView(show: true, text: "Authenticating with Google...")
        
        // Uses view controller to show Google sign-in URL
        GIDSignIn.sharedInstance()?.signIn()
    }
    
    
    // MARK: - View Methods
    func setupView() {

        // Set-up google sign in
        GIDSignIn.sharedInstance()?.delegate = self
        GIDSignIn.sharedInstance()?.presentingViewController = self
    
        // Hide error label
        errorHandler("", isHidden: true)
        
        // Swipe/tap on screen to hide keyboard
        gesturesToHideKeyboard()
        
        playAnimation()
    }
    
    func authStateListener() {
        authHandler = firebaseAuth.addStateDidChangeListener({ (auth, user) in
            
            if self.firebaseAuth.currentUser != nil {
                // Transition to main screen
                self.userExists = true
                self.transitionToMain()
            } else {
                // Stay in sign-in screen
                self.userExists = false
                self.setupView()
            }

        })
    }
    
    func playAnimation() {
        mailmoAnimation.animationSpeed = 0.25
        mailmoAnimation.play(fromFrame: MailmoAnimationFrames.start.rawValue, toFrame: MailmoAnimationFrames.firing.rawValue, loopMode: .none) { _ in
            self.mailmoAnimation.animationSpeed = 0.15
            self.mailmoAnimation.play(fromFrame: MailmoAnimationFrames.firing.rawValue, toFrame: MailmoAnimationFrames.narrow.rawValue, loopMode: .autoReverse, completion: nil)
        }
    }
    
    func hudView(show: Bool, text: String) {
        if show {
            hud.textLabel.text = text
            hud.detailTextLabel.text = nil
            hud.show(in: view, animated: true)
        } else {
            hud.textLabel.text = text
            hud.detailTextLabel.text = nil
            hud.dismiss(animated: true)
            dismiss(animated: true, completion: nil)
        }
    }
    
    func gesturesToHideKeyboard() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - User/Field Validation Methods
    func validateFields() -> String? {
        // Create cleaned versions of the data
        email = emailField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        pass = passwordField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check that all fields are filled in
        if email == "", pass == "" {
            return "Please fill in empty field(s)."
        }
        
        // Check if email is valid
        if !isEmailValid(email) {
            // Email is not valid
            return "Invalid email address."
        }
        
        // Check if password is secure
        if !isPasswordValid(pass) {
            // Password isn't secure enough
            return "Password requires 8+ characters, a special character and a number."
        }
        
        return nil
    }

    // MARK: - Error Handler Methods
    func errorHandler(_ message: String, isHidden: Bool) {
        errorLabel.text = message
        errorLabel.isHidden = isHidden
    }

}

// MARK: - Google Sign-in Delegate Methods
extension SignIn_VC: GIDSignInDelegate {
    
    // Allows app to handle GIDSignIn
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        
        // Check for google sign in error
        if let error = error {
            dismissHud(hud, text: "Error", detailText: error.localizedDescription, delay: 0.5)
            return
        }
        
        // Sign in Google user with firebase
        signIntoFirebase(user: user)
    }
    
    fileprivate func signIntoFirebase(user: GIDGoogleUser!) {
        
        // Check for user's googleAuth and googleCredential
        guard let googleAuth = user.authentication else { return }
        let googleCredential = GoogleAuthProvider.credential(withIDToken: googleAuth.idToken,
                                                             accessToken: googleAuth.accessToken)
        
        // Retrieve google user's email + name
        let email = user.profile.email ?? "No email set"
        let name = user.profile.givenName ?? "No name set"
        print("Successfully authenticated with Google")
        
        // Firebase sign in with googleCredential
        firebaseAuth.signIn(with: googleCredential) { (result, error) in
            
            // Check for firebase sign in error
            if error != nil {
                dismissHud(hud, text: "Error", detailText: "Failed to create a Firebase user with Google", delay: 0.5)
                return
            }
            print("Successfully authenticated with Firebase")

            // Check if user exists
            if let uid = self.firebaseAuth.currentUser?.uid {
                self.firebaseData.child("users/\(uid)").observeSingleEvent(of: .value) { (snapshot) in
                    if snapshot.exists() {
                        // If user exists
                        self.userExists = true
                    } else {
                        // If user doesn't exist, create new user
                        self.userExists = false
                        self.firebaseData.child("users/\(uid)").setValue(["name": name,
                                                                          "email": email])
                    }

                    // Transition to main screen
                    DispatchQueue.main.async {
                        self.transitionToMain()
                    }
                }
            }
            
        }
    }
        
    // Allows app to handle disconnection
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!,
              withError error: Error!) {
        print("User has disconnected")
    }
}
