//
//  Edit_VC.swift
//  Mailmo
//
//  Created by Nadia Siddiqah on 3/23/21.
//

import UIKit
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Firebase
import SwiftMessages

class Edit_VC: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var subjectTextField: UITextField!
    @IBOutlet weak var editTextView: UITextView!
    @IBOutlet weak var sendNowButton: UIButton!
    @IBOutlet weak var sendLaterButton: UIButton!
    
    // MARK: - Variables
    var mailmoSubject = String()
    var to: EmailInfo?
    var from = EmailInfo(email: "sender@em.mailmo.app", name: "Mailmo")
    let today = Date()
    
    var name = String()
    var email = String()
    var prefEmail = String()
    
    let firebaseAuth = Auth.auth()
    let firebaseData = Database.database().reference()
    
    // Body passed from New_VC
    var emailContent = SendGridData(subject: "", body: "", sendAt: nil)
    
    // Semaphore object (to ensure one thread accesses SendGrid at a time)
    var semaphore = DispatchSemaphore(value: 0)
    var sendSuccess = false
    var backToMain = false
    
    // MARK: - View Controller Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
    }
    
    // MARK: - General Methods
    
    func setupView() {
        // Delegates for textField + textView
        subjectTextField.delegate = self
        editTextView.delegate = self
        
        // Retrieve currentUserInfo
        retrieveUserInfo()
            
        // Check if critical currentUserInfo is missing
        checkIfUserInfoIsMissing()
            
        // Initialize editTextView from var passed from New_VC
        editTextView.text = emailContent.body
        
        // Swipe/tap on screen to hide keyboard
        gesturesToHideKeyboard()
    }
    
    func retrieveUserInfo() {
        if let user = currentUserInfo {
            name = user.name
            email = user.email
            prefEmail = user.prefEmail
        }
    }
    
    func checkIfUserInfoIsMissing() {
        if name == n_a && email == n_a && prefEmail == n_a ||
            name == n_a && (email == n_a || prefEmail == n_a) ||
            name == n_a && (email != n_a && prefEmail != n_a) ||
            name != n_a && email == n_a && prefEmail == n_a {
            
            print("Missing info", currentUserInfo!)
            sendButton(enable: false)
            
            DispatchQueue.main.async {
                self.showMissingUserInfoAlert()
            }
        } else {
            // Check if prefEmail is set
            print("No missing info", currentUserInfo!)
            
            sendButton(enable: true)
            
            if prefEmail != n_a {
                to = EmailInfo(email: prefEmail, name: name)
            } else {
                to = EmailInfo(email: email, name: name)
            }
        }
    }
    
    func showMissingUserInfoAlert() {
        let alert = UIAlertController(title: "Missing user information:",
                                      message: "Please fill in missing fields to continue",
                                      preferredStyle: .alert)
        
        // nameField text field
        alert.addTextField { (nameField) in
            nameField.placeholder = "Enter name"
            if self.name == n_a {
                nameField.addTarget(alert, action: #selector(alert.bothFieldsDidChangeInAlert), for: .editingChanged)
            } else {
                nameField.text = self.name
            }
        }
        
        // emailField text field
        alert.addTextField { (emailField) in
            emailField.placeholder = "Enter email"
            if self.prefEmail != n_a {
                emailField.text = self.prefEmail
            } else if self.email != n_a {
                emailField.text = self.email
            } else {
                emailField.addTarget(alert, action: #selector(alert.bothFieldsDidChangeInAlert), for: .editingChanged)
            }
        }
        
        // Cancel button action
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            self.showCancelAlert()
        }))
        
        // Save button action
        let saveAction = UIAlertAction(title: "Save", style: .default, handler: { (_) in
            guard let name = alert.textFields?[0].text,
                  let prefEmail = alert.textFields?[1].text else { return }
            
            let cleanedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanedPrefEmail = prefEmail.trimmingCharacters(in: .whitespacesAndNewlines)
            currentUserInfo?.name = cleanedName
            currentUserInfo?.prefEmail = cleanedPrefEmail
            self.updateData()
            self.sendButton(enable: true)
        })
        saveAction.isEnabled = false
        alert.addAction(saveAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func showCancelAlert() {
        let alert = UIAlertController(title: "Please update missing user info to send email",
                                      message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Update Info", style: .default, handler: { (_) in
            self.showMissingUserInfoAlert()
        }))
        alert.addAction(UIAlertAction(title: "Back to Main", style: .cancel, handler: { (_) in
            self.performSegue(withIdentifier: "unwindFromEditToMain", sender: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func updateData() {
        
        // Post data to Firebase
        if let uid = firebaseAuth.currentUser?.uid {
            print("Successfully posted data to Firebase")
            if let user = currentUserInfo {
                firebaseData.child("users/\(uid)").setValue(["name": user.name,
                                                             "email": user.email,
                                                             "prefEmail": user.prefEmail])
            }
        }
    }
    
    func sendButton(enable: Bool) {
        if enable {
            sendNowButton.isEnabled = true
            sendLaterButton.isEnabled = true
        } else {
            sendNowButton.isEnabled = false
            sendLaterButton.isEnabled = false
        }
    }
    
    // MARK: - Send Methods
    @IBAction func sendNow(_ sender: Any) {
        hudView(show: true, text: "Preparing to send...")
        sendEmail()
        if sendSuccess {
            postData()
            dismissHud(hud, text: "Preparing to send...", detailText: "", delay: 0.8)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                self.performSegue(withIdentifier: "showSendNow", sender: nil)
            }
        }
    }
    
    @IBAction func sendLater(_ sender: Any) {
        performSegue(withIdentifier: "showSendLaterPicker", sender: nil)
    }
    
    // MARK: - Navigation Methods
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSendNow" {
           _ = segue.destination as! SendNow_VC
        } else if segue.identifier == "showSendLaterPicker" {
            let controller = segue.destination as! DatePicker_VC
            controller.to = to!
            controller.from = from
            controller.email.subject = subjectTextField.text ?? ""
            controller.email.body = editTextView.text
        }
    }
    
    @IBAction func unwindFromSendLaterPicker(_ unwindSegue: UIStoryboardSegue) {
    }
    
    // MARK: - Helper Methods
    func hudView(show: Bool, text: String) {
        if show {
            hud.textLabel.text = text
            hud.detailTextLabel.text = nil
            hud.show(in: view, animated: true)
        }
    }
    
    func gesturesToHideKeyboard() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tap)
        editTextView.keyboardDismissMode = .onDrag
    }
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
    
    func checkforEmptySubject() {
        let defaultSubject = DateFormatter()
        defaultSubject.dateFormat = "M-d h:mm"
        
        if let subject = subjectTextField.text {
            if subject == "" {
                emailContent.subject = "New Mailmo \(defaultSubject.string(from: today))"
            } else {
                emailContent.subject = subject
            }
            print(emailContent.subject)
        }
    }
    
    func postData() {
        let sendTime = convertDateToString(today)
        
        // Post data to Firebase
        if let uid = firebaseAuth.currentUser?.uid {
            print("Successfully posted data to Firebase")
            firebaseData.child("posts/\(uid)").child(calculateSendTime()).setValue(["subject": emailContent.subject,
                                                                                    "body": emailContent.body,
                                                                                    "sendAtString": sendTime])
        }
    }
    
    func sendEmail() {
        // Email String Object (w/ personalization parameters)
        checkforEmptySubject()
        let emailString = emailFormatter(to: to!.email, toName: to!.name!,
                                         from: from.email, fromName: from.name!,
                                         subject: emailContent.subject, body: emailContent.body,
                                         sendAt: nil)
        
        // Convert Email String -> UTF8 Data Object
        let emailData = emailString.data(using: .utf8)
        
        // Create SendGrid urlRequest
        var urlRequest = URLRequest(url: URL(string: "https://api.sendgrid.com/v3/mail/send")!,
                                 timeoutInterval: Double.infinity)
        // Check if sendGrid API key is broken
        guard let apiKey = Bundle.main.infoDictionary?["SendGridAPI_Key"] as? String else {
            sendSuccess = false
            handleInvalidAPI()
            return
        }
        // Access sendGridAPI environment var for Authorization Value
        urlRequest.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        // Add Content-Type value
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // "POST"/send emailData to SendGrid URL
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = emailData
        
        // Create shared SendGrid URLSession dataTask object
        let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            guard let data = data else {
                // Show error if no data received from SendGrid + suspend semaphore
                self.sendSuccess = false
                print(String(describing: error))
                self.semaphore.signal()
                return
            }
            // Suspend semaphore if data is received from SendGrid
            self.sendSuccess = true
            print(String(data: data, encoding: .utf8)!)
            self.semaphore.signal()
        }
        // Resume task (post emailData to SendGrid) + start semaphore
        dataTask.resume()
        semaphore.wait()
    }
    
    // MARK: - Error Handling Methods
    func handleInvalidAPI() {
        let alert = UIAlertController(title: "Error has occurred",
                                      message: "Mailmo email server is currently unavailable.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Back to Main", style: .cancel, handler: { (_) in
            self.performSegue(withIdentifier: "unwindFromEditToMain", sender: nil)
        }))
        present(alert, animated: true, completion: nil)
    }
}

// MARK: - Text Field Delegate Methods
extension Edit_VC: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let enteredSubject = subjectTextField.text {
            mailmoSubject = enteredSubject
        }
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Ends all editing
        view.endEditing(true)
        return false
    }
}

// MARK: - Text View Delegate Methods
extension Edit_VC: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        if textView.text == "" {
            sendNowButton.isEnabled = false
            sendLaterButton.isEnabled = false
        } else {
            sendNowButton.isEnabled = true
            sendLaterButton.isEnabled = true
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if let enteredText = editTextView.text {
            let textWithBreaks = enteredText.replacingOccurrences(of: "\n", with: "<br>")
            emailContent.body = textWithBreaks
        }
        view.endEditing(true)
    }
}
