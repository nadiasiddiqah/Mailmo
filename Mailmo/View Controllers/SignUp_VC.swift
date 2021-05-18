//
//  SignUp_VC.swift
//  Mailmo
//
//  Created by Nadia Siddiqah on 5/4/21.
//

import UIKit
import Firebase
import GoogleSignIn

class SignUp_VC: UIViewController {
    
    // MARK: - Variables
    let firebaseAuth = Auth.auth()
    let firebaseData = Database.database().reference()
    
    var name = String()
    var email = String()
    var pass = String()
    var confirmPass = String()
    
    var msgBody = String()
    var userExists = false
    
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
        navigationController?.popViewController(animated: true)
    }
    
    func transitionToMain() {
        // Dismiss HUD
        if userExists {
            hudView(show: false, text: "Logging in...")
        } else {
            hudView(show: false, text: "Creating new account...")
        }
        userExists = false
        
        // Set new rootVC as MainVC (when user logs in)
        let mainVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "MainVC") as! Main_VC
        mainVC.msgBody = msgBody
        view.window?.rootViewController = mainVC
        view.window?.makeKeyAndVisible()
    }
    
    @IBAction func backToLogin(_ sender: Any) {
        navigationController?.popViewController(animated: true)
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
            firebaseAuth.createUser(withEmail: email, password: pass) { (result, error) in
                if let error = error {
                    // Failed to create user
                    print("Failed to create new user", error)
                    self.errorHandler("\(error.localizedDescription)", isHidden: false)
                    return
                }
                
                // Created user successfully
                guard let uid = result?.user.uid else { return }
                
                self.errorHandler("", isHidden: true)
                print("Successfully created new user")
                
                self.firebaseData.child("users/\(uid)").setValue(["name": self.name.capitalized,
                                                                  "email": self.email])
                self.msgBody = "Welcome to Mailmo, \(self.name)!"
                
                // Transition to main screen
                DispatchQueue.main.async {
                    self.transitionToMain()
                }
            }
        }
        
    }
    
    @IBAction func signUpWithApple(_ sender: Any) {
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
        
        // Swipe/tap on screen to hide keyboard
        gesturesToHideKeyboard()
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
        name = nameField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        email = emailField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        pass = passwordField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        confirmPass = confirmPasswordField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check that all fields are filled in
        if email == "", pass == "", confirmPass == "" {
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
        
        // Retrive google user's email + name
        let email = user.profile.email ?? "No email set"
        name = user.profile.givenName ?? "No name set"
        if name != "No name set" {
            msgBody = "Welcome back, \(name)!"
        } else {
            msgBody = "Welcome back!"
        }
        print("Successfully authenticated with Google")
        
        // Firebase sign in with googleCredential
        firebaseAuth.signIn(with: googleCredential) { (result, error) in
        
            // Check for firebase sign in error
            if error != nil {
                dismissHud(hud, text: "Error", detailText: "Failed to create a Firebase user with Google", delay: 1)
                return
            }
            
            // Check if user exists
            if let uid = self.firebaseAuth.currentUser?.uid {
                self.firebaseData.child("users/\(uid)").observeSingleEvent(of: .value) { (snapshot) in
                    if snapshot.exists() {
                        // If user exists
                        self.userExists = true
                        self.msgBody = "Welcome back, \(self.name)!"
                    } else {
                        // If user doesn't exist, create new user
                        self.userExists = false
                        self.msgBody = "Welcome to Mailmo, \(self.name)!"
                        self.firebaseData.child("users/\(uid)").setValue(["name": self.name,
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
