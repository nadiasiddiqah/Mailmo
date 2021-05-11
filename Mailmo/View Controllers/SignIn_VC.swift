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

class SignIn_VC: UIViewController {
    
    // MARK: - Variables
    let firebaseAuth = Auth.auth()
    let firebaseData = Database.database().reference()
    var authHandler: AuthStateDidChangeListenerHandle?
    
    var email = String()
    var pass = String()
    
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
        
        setupView()
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
        
        // Set new rootVC as MainVC (when user logs in)
        let mainVC = storyboard?.instantiateViewController(identifier: "MainVC") as? Main_VC
        view.window?.rootViewController = mainVC
        view.window?.makeKeyAndVisible()
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
    
            // Log in User
            firebaseAuth.signIn(withEmail: email, password: pass) { (result, error) in
                if let error = error {
                    // Firebase sign in error
                    print("Failed to create user", error)
                    self.errorHandler("\(error.localizedDescription)", isHidden: false)
                } else {
                    // Sign in successful
                    self.errorHandler("", isHidden: true)
                    self.transitionToMain()
                }
            }
        }
        
    }
    
    @IBAction func logInWithApple(_ sender: Any) {
    }
    
    @IBAction func logInWithGoogle(_ sender: Any) {
        GIDSignIn.sharedInstance()?.signIn()
    }
    
    
    // MARK: - View Methods
    func setupView() {
        // Check if user is not logged in
        if firebaseAuth.currentUser != nil {
            // Log user out
            do {
                try firebaseAuth.signOut()
            } catch {
                print("Error signing out: %@", error)
            }
        }
        
        // Hide error label
        errorHandler("", isHidden: true)
        
        // Uses view controller to show Google sign-in URL
        GIDSignIn.sharedInstance()?.presentingViewController = self
        
        // Listens for changes in user auth status
        authHandler = firebaseAuth.addStateDidChangeListener({ (auth, user) in
            self.checkLogInStatus()
        })
        
        // Swipe/tap on screen to hide keyboard
        gesturesToHideKeyboard()
        
        playAnimation()
    }
    
    func playAnimation() {
        mailmoAnimation.animationSpeed = 0.25
        mailmoAnimation.play(fromFrame: MailmoAnimationFrames.start.rawValue, toFrame: MailmoAnimationFrames.firing.rawValue, loopMode: .none) { _ in
            self.mailmoAnimation.animationSpeed = 0.15
            self.mailmoAnimation.play(fromFrame: MailmoAnimationFrames.firing.rawValue, toFrame: MailmoAnimationFrames.narrow.rawValue, loopMode: .autoReverse, completion: nil)
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
    
    // MARK: - User/Field Validation Methods
    func validateFields() -> String? {
        // Create cleaned versions of the data
        email = emailField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        pass = passwordField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check that all fields are filled in
        if email == "", pass == "" {
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
        
        return nil
    }
    
    // Determines if app can log user in + transition to main
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
