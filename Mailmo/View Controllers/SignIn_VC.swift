//
//  SignIn_VC.swift
//  Mailmo App
//
//  Created by Nadia Siddiqah on 3/16/21.
//

import UIKit
import Lottie
import GoogleSignIn
import AuthenticationServices
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
    var showTutorialView = false
    
    fileprivate var currentNonce: String?
    
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
        Utils.loadAnimation(fileName: "mailmoIconAnimation", loadingView: mailmoIcon)
    }()
    
    // MARK: - View Controller Methods
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
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
        print("transition to main")
        // Dismiss HUD
        Utils.hud.dismiss(animated: true)
        dismiss(animated: true, completion: nil)
        
        // Set new rootVC as MainVC (when user logs in)
        let mainVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "MainVC") as! Main_VC
        mainVC.userExists = userExists
        mainVC.showWelcomePopup = true
        mainVC.showTutorialView = showTutorialView
    
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
            firebaseAuth.signIn(withEmail: email, password: pass) { [weak self] (result, error) in
                
                guard let self = self else { return }
                
                if error != nil {
                    // Firebase sign in error
                    Utils.dismissHud(Utils.hud, text: "Error", detailText: "Failed to create new user", delay: 0.5)
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
        
        // Show HUD view
        hudView(show: true, text: "Authenticating with Apple...")
        
        // Generate nonce
        let nonce = Utils.randomNonceString()
        currentNonce = nonce
    
        // Create apple auth request
        let appleAuthRequest = ASAuthorizationAppleIDProvider().createRequest()
        appleAuthRequest.requestedScopes = [.fullName, .email]
        appleAuthRequest.nonce = Utils.sha256(nonce)
    
        // Present apple auth controller
        let authController = ASAuthorizationController(authorizationRequests: [appleAuthRequest])
        authController.delegate = self
        authController.presentationContextProvider = self
        authController.performRequests()
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

        authHandler = firebaseAuth.addStateDidChangeListener({ [weak self] (auth, user) in
            
            guard let strongSelf = self else { return }
            
            if Utils.hud.isHidden {
                if strongSelf.firebaseAuth.currentUser != nil {
                    // Transition to main screen
                    strongSelf.userExists = true
                    strongSelf.transitionToMain()
                } else {
                    // Stay in sign-in screen
                    strongSelf.userExists = false
                    strongSelf.setupView()
                }
            }

        })
    }
    
    func playAnimation() {
        mailmoAnimation.animationSpeed = 0.25
        mailmoAnimation.play(fromFrame: MailmoAnimationFrames.start.rawValue, toFrame: MailmoAnimationFrames.firing.rawValue, loopMode: .none) { [weak self] _ in
            guard let strongSelf = self else { return }
            strongSelf.mailmoAnimation.animationSpeed = 0.15
            strongSelf.mailmoAnimation.play(fromFrame: MailmoAnimationFrames.firing.rawValue, toFrame: MailmoAnimationFrames.narrow.rawValue, loopMode: .autoReverse, completion: nil)
        }
    }
    
    func hudView(show: Bool, text: String) {
        if show {
            Utils.hud.textLabel.text = text
            Utils.hud.detailTextLabel.text = nil
            Utils.hud.show(in: view, animated: true)
        } else {
            Utils.hud.textLabel.text = text
            Utils.hud.detailTextLabel.text = nil
            Utils.hud.dismiss(animated: true)
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
        if !Utils.isEmailValid(email) {
            // Email is not valid
            return "Invalid email address."
        }
        
        // Check if password is secure
        if !Utils.isPasswordValid(pass) {
            // Password isn't secure enough
            return "Password requires 8+ characters, a special character and a number."
        }
        
        return nil
    }

    func checkIfUserExistsInFirebase(name: String, email: String) {
        print("name: \(name), email: \(email)")
        if let uid = self.firebaseAuth.currentUser?.uid {
            self.firebaseData.child("users/\(uid)").observeSingleEvent(of: .value) { [weak self] (snapshot) in
                
                guard let strongSelf = self else { return }
                
                if snapshot.exists() {
                    // If user exists
                    strongSelf.userExists = true
                    strongSelf.showTutorialView = false
                } else {
                    // If user doesn't exist, create new user
                    strongSelf.userExists = false
                    strongSelf.showTutorialView = true
                    strongSelf.firebaseData.child("users/\(uid)").setValue(["name": name,
                                                                            "email": email])
                }

                // Transition to main screen
                DispatchQueue.main.async {
                    self?.transitionToMain()
                }
            }
        }
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
            Utils.dismissHud(Utils.hud, text: "Error", detailText: error.localizedDescription, delay: 0.5)
            return
        }
        
        // Sign in Google user with firebase
        signIntoFirebaseViaGoogle(user: user)
    }
    
    fileprivate func signIntoFirebaseViaGoogle(user: GIDGoogleUser!) {
        
        // Check for user's googleAuth and googleCredential
        guard let googleAuth = user.authentication else { return }
        let googleCredential = GoogleAuthProvider.credential(withIDToken: googleAuth.idToken,
                                                             accessToken: googleAuth.accessToken)
        
        // Retrieve google user's email + name
        let email = user.profile.email ?? "Not Set"
        let name = user.profile.givenName ?? "Not Set"
        print("Successfully authenticated with Google")
        
        // Firebase sign in with googleCredential
        firebaseAuth.signIn(with: googleCredential) { [weak self] (result, error) in
            
            guard let strongSelf = self else { return }
            
            // Check for firebase sign in error
            if error != nil {
                Utils.dismissHud(Utils.hud, text: "Error", detailText: "Failed to create a Firebase user with Google", delay: 0.5)
                return
            }
            print("Successfully authenticated with Firebase")

            // Check if user exists
            strongSelf.checkIfUserExistsInFirebase(name: name, email: email)
            
        }
    }
        
    // Allows app to handle disconnection
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!,
              withError error: Error!) {
        print("User has disconnected")
    }
}

extension SignIn_VC: ASAuthorizationControllerDelegate {
    
    // Handle apple authorization error
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        
        guard let error = error as? ASAuthorizationError else { return }

        switch error.code {
        case .canceled:
            Utils.dismissHud(Utils.hud, text: "Error", detailText: "Apple authorization cancelled", delay: 0.5)
        case .invalidResponse:
            Utils.dismissHud(Utils.hud, text: "Error", detailText: "Apple authorization invalid", delay: 0.5)
        case .failed:
            Utils.dismissHud(Utils.hud, text: "Error", detailText: "Apple authorization failed", delay: 0.5)
        default:
            Utils.dismissHud(Utils.hud, text: "Error", detailText: "Apple authorization error", delay: 0.5)
        }
    }
    
    // Handle apple authorization screen
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {

        if let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential {

            signIntoFirebaseViaApple(appleCredential: appleCredential)
        }
    }
    
    fileprivate func signIntoFirebaseViaApple(appleCredential: ASAuthorizationAppleIDCredential) {

        guard let nonce = currentNonce else {
            fatalError("Invalid state: A login callback was received, but no login request was sent.")
        }

        guard let idToken = appleCredential.identityToken else {
            print("Unable to fetch identity token")
            return
        }

        guard let idTokenString = String(data: idToken, encoding: .utf8) else {
            print("Unable to serialize token from data", idToken.debugDescription)
            return
        }

        // Retrieve apple user's email + name
        let email = appleCredential.email ?? "Not Set"
        let name = appleCredential.fullName?.givenName ?? "Not Set"

        print("Successfully authenticated with Apple")

        // Initialize Firebase credential with apple idTokenString
        let firebaseCredential = OAuthProvider.credential(withProviderID: "apple.com",
                                                          idToken: idTokenString,
                                                          rawNonce: nonce)

        // Firebase sign in
        firebaseAuth.signIn(with: firebaseCredential) { [weak self] (result, error) in
            
            guard let strongSelf = self else { return }
            
            // Check for firebase sign in error
            if error != nil {
                Utils.dismissHud(Utils.hud, text: "Error", detailText: "Failed to create a Firebase user with Apple", delay: 0.5)
                return
            }
            print("Successfully authenticated with Firebase")
            
            // Check if user exists
            DispatchQueue.main.async {
                strongSelf.checkIfUserExistsInFirebase(name: name, email: email)
            }

        }

    }
    
}

extension SignIn_VC: ASAuthorizationControllerPresentationContextProviding {
    
    // Present apple auth in current view window
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return view.window!
    }
    
}
