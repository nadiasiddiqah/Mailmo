//
//  SignUp_VC.swift
//  Mailmo
//
//  Created by Nadia Siddiqah on 5/4/21.
//

import UIKit
import Firebase
import GoogleSignIn
import AuthenticationServices

class SignUp_VC: UIViewController {
    
    // MARK: - Variables
    let firebaseAuth = Auth.auth()
    let firebaseData = Database.database().reference()
    
    var name = String()
    var email = String()
    var pass = String()
    var confirmPass = String()
    
    var userExists = false
    var showTutorialView = true
    
    fileprivate var currentNonce: String?
    
    // MARK: - Outlets
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var confirmPasswordField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    
    // MARK: - View Controller Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
    }
    
    // MARK: - Navigation
    @IBAction func backButton(_ sender: Any) {
        performSegue(withIdentifier: "unwindToSignIn", sender: nil)
    }
    
    func transitionToMain() {
        // Dismiss HUD
        Utils.hud.dismiss(animated: true)
        dismiss(animated: true, completion: nil)
        
        // Set new rootVC as MainVC (when user logs in)
        let mainVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "MainVC") as! Main_VC
        mainVC.userExists = userExists
        mainVC.showWelcomePopup = true
        mainVC.showTutorialView = showTutorialView
        print(showTutorialView)
        
        view.window?.rootViewController = mainVC
        view.window?.makeKeyAndVisible()
    }
    
    @IBAction func backToLogin(_ sender: Any) {
        performSegue(withIdentifier: "unwindToSignIn", sender: nil)
    }
    
    // MARK: - Action Methods
    @IBAction func signUpWithEmail(_ sender: Any) {
        
        // Validate Text Fields
        let errorMessage = validateFields()
        
        if errorMessage != nil {
            // Something wrong in the fields, show error message
            errorHandler(errorMessage!, isHidden: false)
        } else {
            // No errors in fields
            errorHandler("", isHidden: true)
            
            // Show HUD view
            hudView(show: true, text: "Creating new account...")
            
            // Create new user
            firebaseAuth.createUser(withEmail: email, password: pass) { [weak self] (result, error) in
                
                guard let strongSelf = self else { return }
                
                if error != nil {
                    // Failed to create user
                    Utils.dismissHud(Utils.hud, text: "Error", detailText: "Failed to create new user", delay: 0.5)
                    return
                }
                
                // Created user successfully
                if let uid = result?.user.uid {
                    print("Successfully created new user")
                    strongSelf.userExists = false
                    strongSelf.errorHandler("", isHidden: true)
                    
                    strongSelf.firebaseData.child("users/\(uid)").setValue(["name": strongSelf.name.capitalized,
                                                                            "email": strongSelf.email])
                    // Transition to main screen
                    DispatchQueue.main.async {
                        strongSelf.transitionToMain()
                    }
                }
        
            }
        }
        
    }
    
    @IBAction func signUpWithApple(_ sender: Any) {
        
        // Show HUD view
        hudView(show: true, text: "Authenticating with Apple...")
        
        // Generate nonce
        let nonce = RandomNonceGenerator.randomNonceString()
        currentNonce = nonce
    
        // Create apple auth request
        let appleAuthRequest = ASAuthorizationAppleIDProvider().createRequest()
        appleAuthRequest.requestedScopes = [.fullName, .email]
        appleAuthRequest.nonce = RandomNonceGenerator.sha256(nonce)
    
        // Present apple auth controller
        let authController = ASAuthorizationController(authorizationRequests: [appleAuthRequest])
        authController.delegate = self
        authController.presentationContextProvider = self
        authController.performRequests()
    }
    
    @IBAction func signUpWithGoogle(_ sender: Any) {
        // Show HUD view
        hudView(show: true, text: "Authenticating with Google...")
        
        // Set view controller as GIDSignIn delegate + presentingVC
        GIDSignIn.sharedInstance()?.delegate = self
        GIDSignIn.sharedInstance()?.presentingViewController = self
        
        // Uses view controller to show Google sign-in URL
        GIDSignIn.sharedInstance()?.signIn()
    }
    
    // MARK: - View Methods
    func setupView() {
        
        // Hide error label
        errorHandler("", isHidden: true)
        
        // Default state
        userExists = false
        
        // Swipe/tap on screen to hide keyboard
        gesturesToHideKeyboard()
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
        name = nameField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        email = emailField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        pass = passwordField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        confirmPass = confirmPasswordField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check that all fields are filled in
        if email == "", pass == "", confirmPass == "" {
            return "Please fill in empty field(s)."
        }
        
        // Check if email is valid
        if !SendEmail_VM.isEmailValid(email) {
            // Email is not valid
            return "Invalid email address."
        }
        
        // Check if password is secure
        if !SendEmail_VM.isPasswordValid(pass) {
            // Password isn't secure enough
            return "Password requires 8+ characters, a special character and a number."
        }
        
        // Check if password and confirmPassword field are equal
        if pass != confirmPass {
            // Pass and confirmPass don't match
            return "Passwords do not match. Please try again."
        }
        
        return nil
    }
    
    // Determines if app can log user in + transitions to main
    fileprivate func checkLogInStatus() {
        DispatchQueue.main.async {
            if self.firebaseAuth.currentUser != nil {
                self.transitionToMain()
            }
        }
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
                    strongSelf.firebaseData.child("users/\(uid)").setValue(["name": name,
                                                                            "email": email])
                }

                // Transition to main screen
                DispatchQueue.main.async {
                    strongSelf.transitionToMain()
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

extension SignUp_VC: GIDSignInDelegate {
    // MARK: - Google Sign-in Delegate Methods
    
    // Allows app to handle GIDSignIn
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!,
              withError error: Error!) {
        
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
        
        // Retrive google user's email + name
        let email = user.profile.email ?? "Not Set"
        name = user.profile.givenName ?? "Not Set"
        print("Successfully authenticated with Google")
        
        // Firebase sign in with googleCredential
        firebaseAuth.signIn(with: googleCredential) { [weak self] (result, error) in
            
            guard let strongSelf = self else { return }
        
            // Check for firebase sign in error
            if error != nil {
                Utils.dismissHud(Utils.hud, text: "Error", detailText: "Failed to create a Firebase user with Google", delay: 1)
                return
            }
            print("Successfully authenticated with Firebase")
            
            // Check if user exists
            strongSelf.checkIfUserExistsInFirebase(name: strongSelf.name, email: email)
        }
    }
        
    // Allows app to handle disconnection
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!,
              withError error: Error!) {
        print("User has disconnected")
    }
}

extension SignUp_VC: ASAuthorizationControllerDelegate {
    
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

extension SignUp_VC: ASAuthorizationControllerPresentationContextProviding {
    
    // Present apple auth in current view window
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return view.window!
    }
    
}
