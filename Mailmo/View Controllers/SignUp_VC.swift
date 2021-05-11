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
    var authHandler: AuthStateDidChangeListenerHandle?
    
    var name = String()
    var email = String()
    var pass = String()
    var confirmPass = String()
    
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
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }
    
    func transitionToMain() {
        
        // Set new rootVC as MainVC (when user logs in)
        let mainVC = storyboard?.instantiateViewController(identifier: "MainVC") as? Main_VC
        view.window?.rootViewController = mainVC
        view.window?.makeKeyAndVisible()
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
            
            // Create new user
            firebaseAuth.createUser(withEmail: email, password: pass) { (result, error) in
                if let error = error {
                    // Failed to create user
                    print("Failed to create user", error)
                    self.errorHandler("\(error.localizedDescription)", isHidden: false)
                    return
                }
                
                guard let uid = result?.user.uid else { return }
                
                // Created user successfully
                self.errorHandler("", isHidden: true)
                print("Successfully created new user")
                self.firebaseData.child("users/\(uid)").setValue(["name": self.name,
                                                                  "email": self.email])
            }
            
            // Register new user with authHandler
            authHandler = firebaseAuth.addStateDidChangeListener({ (auth, user) in
                // Check if new user is logged in + transition to main
                self.checkLogInStatus()
            })
        }
        
    }
    
    @IBAction func signUpWithApple(_ sender: Any) {
    }
    
    @IBAction func signUpWithGoogle(_ sender: Any) {
        GIDSignIn.sharedInstance()?.signIn()
    }
    
    @IBAction func backToLogin(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - View Methods
    func setupView() {
        
        // Hide error label
        errorHandler("", isHidden: true)
        
        // Swipe/tap on screen to hide keyboard
        gesturesToHideKeyboard()
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
            return "Error: Please fill in empty field(s)."
        }
        
        // Check if email is valid
        if !isEmailValid(email) {
            // Email is not valid
            return "Error: Invalid email address."
        }
        
        // Check if password is secure
        if !isPasswordValid(pass) {
            // Password isn't secure enough
            return "Error: Password requires 8+ characters, a special character and a number."
        }
        
        // Check if password and confirmPassword field are equal
        if pass != confirmPass {
            // Pass and confirmPass don't match
            return "Error: Passwords do not match. Please try again."
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
    
    // MARK: - Helper Methods
    func gesturesToHideKeyboard() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Error Handler Methods
    func errorHandler(_ message: String, isHidden: Bool) {
        errorLabel.text = message
        errorLabel.isHidden = isHidden
    }

}
