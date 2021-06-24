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
import MessageUI

class Settings_VC: UIViewController {
    
    // MARK: - Variables
    let firebaseAuth = Auth.auth()
    let firebaseData = Database.database().reference()
    
    // MARK: - Outlets
    @IBOutlet weak var emailButton: UIButton!
    
    // MARK: - View Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
    }
    
    // MARK: - Navigation
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
    @IBAction func changeEmail(_ sender: Any) {
        
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Would you like to update your email address?",
                                          message: nil,
                                          preferredStyle: .alert)
            alert.addTextField { (textField) in
                textField.placeholder = "Enter new email"
                textField.addTarget(alert, action: #selector(alert.fieldDidChangeInAlert), for: .editingChanged)
            }
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            let saveAction = UIAlertAction(title: "Save", style: .default, handler: { [weak self] (_) in
                guard let strongSelf = self else { return }
                
                guard let prefEmail = alert.textFields?[0].text else { return }
                
                let cleanedPrefEmail = prefEmail.trimmingCharacters(in: .whitespacesAndNewlines)
                strongSelf.emailButton.setTitle("\(cleanedPrefEmail)", for: .normal)
                Utils.currentUserInfo?.prefEmail = cleanedPrefEmail
                strongSelf.postPrefEmail()
            })
            saveAction.isEnabled = false
            alert.addAction(saveAction)
            
            self.present(alert, animated: true, completion: nil)
        }
        
    }
    
    @IBAction func pressedLogOut(_ sender: Any) {
        let alert = UIAlertController(title: nil,
                                      message: "Are you sure you want to log out?",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { [weak self] (_) in
            guard let strongSelf = self else { return }

            strongSelf.logOut()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.pruneNegativeWidthConstraints()
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func pressedRate(_ sender: Any) {
        let alert = UIAlertController(title: "Enjoying Mailmo?",
                                      message: "Your app store review helps spread the word and improve the Mailmo app!",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Rate Now", style: .default, handler: { [weak self] (_) in
            guard let strongSelf = self else { return }
            strongSelf.pressedRateNow()
        }))
        alert.addAction(UIAlertAction(title: "Send Feedback", style: .default, handler: { [weak self] (_) in
            guard let strongSelf = self else { return }
            strongSelf.pressedSendFeedback()
        }))
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func pressedRateNow() {
        guard let scene = view.window?.windowScene else { return }
        AppStoreReviewManager.requestReviewIfAppropriate(scene: scene)
        
        // In case user already has reviewed app, direct them to app store link
        guard let writeReviewURL = URL(string: "https://apps.apple.com/app/id1570551825?action=write-review") else {
            let alert = UIAlertController(title: "Error", message: "Error in loading App Store Review.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
            return
        }
        UIApplication.shared.open(writeReviewURL, options: [:], completionHandler: nil)
    }
    
    func pressedSendFeedback() {
        let subject = "Mailmo - Send Feedback / Contact Us"
        let sendTo = "nadiasiddiqah@gmail.com"
        
        // Check if user has email set up
        if MFMailComposeViewController.canSendMail() {
            let mailComposeVC = MFMailComposeViewController()
            mailComposeVC.mailComposeDelegate = self
            mailComposeVC.setSubject(subject)
            mailComposeVC.setToRecipients([sendTo])
            
            present(mailComposeVC, animated: true, completion: nil)
        } else {
            guard let sendEmailURL = URL(string: "https://www.mailmo.app") else {
                let alert = UIAlertController(title: "Error", message: "Unable to access Mail App.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
                return
            }
            UIApplication.shared.open(sendEmailURL, options: [:], completionHandler: nil)
        }
    
    }
    
    // MARK: - View Methods
    func setupView() {
        retrieveEmail()
    }
    
    // MARK: - Methods
    func retrieveEmail() {
        emailButton.titleLabel?.minimumScaleFactor = 0.5
        emailButton.titleLabel?.numberOfLines = 1
        emailButton.titleLabel?.adjustsFontSizeToFitWidth = true
        if let user = Utils.currentUserInfo {
            if user.prefEmail == Utils.n_a {
                emailButton.setTitle("\(user.email)", for: .normal)
            } else {
                emailButton.setTitle("\(user.prefEmail)", for: .normal)
            }
        }
    }
    
    func postPrefEmail() {
        
        // Post data to Firebase
        if let uid = firebaseAuth.currentUser?.uid {
            print("Successfully posted data to Firebase")
            if let user = Utils.currentUserInfo { 
                firebaseData.child("users/\(uid)").setValue(["name": user.name,
                                                             "email": user.email,
                                                             "prefEmail": user.prefEmail])
            }

        }
    }
    
    func logOut() {
        // Show HUD
        hudView(show: true, text: "Logging out...")
        
        // Sign user out of Google
        GIDSignIn.sharedInstance()?.signOut()
        
        // Sign user out of Firebase
        do {
            try Auth.auth().signOut()
            transitionToSignIn()
        } catch {
            Utils.dismissHud(Utils.hud, text: "Error", detailText: error.localizedDescription, delay: 1)
        }
        print("Logged out")
    }
    
    
    func hudView(show: Bool, text: String) {
        if show {
            Utils.hud.textLabel.text = text
            Utils.hud.detailTextLabel.text = nil
            Utils.hud.show(in: view, animated: true)
        } else {
            Utils.hud.dismiss(afterDelay: 1.5, animated: true)
        }
    }
    
}

extension Settings_VC: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult, error: Error?) {
        
        if let _ = error {
            controller.dismiss(animated: true, completion: nil)
            return
        }

        var text = String()
        switch result {
        case .cancelled:
            text = "Cancelling..."
        case .failed:
            text = "Failed to Send Feedback"
        case .saved:
            text = "Feedback Saved"
        case .sent:
            text = "Feedback Sent!"
        @unknown default:
            text = "Error in Sending Feedback..."
        }

        hudView(show: true, text: text)
        controller.dismiss(animated: true, completion: nil)
        hudView(show: false, text: "")
    }
}

struct EmailParameters {
    /// Guaranteed to be non-empty
    let toEmails: [String]
    let ccEmails: [String]
    let bccEmails: [String]
    let subject: String?
    let body: String?

    /// Defaults validation is just verifying that the email is not empty.
    static func defaultValidateEmail(_ email: String) -> Bool {
        return !email.isEmpty
    }

    /// Returns `nil` if `toEmails` contains at least one email address validated by `validateEmail`
    /// A "blank" email address is defined as an address that doesn't only contain whitespace and new lines characters, as defined by CharacterSet.whitespacesAndNewlines
    /// `validateEmail`'s default implementation is `defaultValidateEmail`.
    init?(
        toEmails: [String],
        ccEmails: [String],
        bccEmails: [String],
        subject: String?,
        body: String?,
        validateEmail: (String) -> Bool = defaultValidateEmail
    ) {
        func parseEmails(_ emails: [String]) -> [String] {
            return emails.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter(validateEmail)
        }
        let toEmails = parseEmails(toEmails)
        let ccEmails = parseEmails(ccEmails)
        let bccEmails = parseEmails(bccEmails)
        if toEmails.isEmpty {
            return nil
        }
        self.toEmails = toEmails
        self.ccEmails = ccEmails
        self.bccEmails = bccEmails
        self.subject = subject
        self.body = body
    }

    /// Returns `nil` if `scheme` is not `mailto`, or if it couldn't find any `to` email addresses
    /// `validateEmail`'s default implementation is `defaultValidateEmail`.
    /// Reference: https://tools.ietf.org/html/rfc2368
    init?(url: URL, validateEmail: (String) -> Bool = defaultValidateEmail) {
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        let queryItems = urlComponents.queryItems ?? []
        func splitEmail(_ email: String) -> [String] {
            return email.split(separator: ",").map(String.init)
        }
        let initialParameters = (toEmails: urlComponents.path.isEmpty ? [] : splitEmail(urlComponents.path), subject: String?(nil), body: String?(nil), ccEmails: [String](), bccEmails: [String]())
        let emailParameters = queryItems.reduce(into: initialParameters) { emailParameters, queryItem in
            guard let value = queryItem.value else {
                return
            }
            switch queryItem.name {
            case "to":
                emailParameters.toEmails += splitEmail(value)
            case "cc":
                emailParameters.ccEmails += splitEmail(value)
            case "bcc":
                emailParameters.bccEmails += splitEmail(value)
            case "subject" where emailParameters.subject == nil:
                emailParameters.subject = value
            case "body" where emailParameters.body == nil:
                emailParameters.body = value
            default:
                break
            }
        }
        self.init(
            toEmails: emailParameters.toEmails,
            ccEmails: emailParameters.ccEmails,
            bccEmails: emailParameters.bccEmails,
            subject: emailParameters.subject,
            body: emailParameters.body,
            validateEmail: validateEmail
        )
    }
}
