//
//  New_Edit_VC.swift
//  Mailmo
//
//  Created by Nadia Siddiqah on 3/23/21.
//

import UIKit
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

class New_Edit_VC: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var subjectTextField: UITextField!
    @IBOutlet weak var editTextView: UITextView!
    @IBOutlet weak var sendNowButton: UIButton!
    @IBOutlet weak var sendLaterButton: UIButton!
    
    // MARK: - Variables
    var mailmoSubject = String()
    var to = EmailInfo(email: "nadiasiddiqah@gmail.com", name: "Nadia")
    var from = EmailInfo(email: "nadiasiddiqah@gmail.com", name: "Mailmo")
    
    // Body passed from New_VC
    var email = EmailContent(subject: "", body: "")
    
    // Semaphore object (to ensure one thread accesses SendGrid at a time)
    var semaphore = DispatchSemaphore(value: 0)
    var sendSuccess = false
    
    // MARK: - View Controller Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupEditView()
    }
    
    // MARK: - General Methods
    func setupEditView() {
        // Delegates for textField + textView
        subjectTextField.delegate = self
        editTextView.delegate = self
        
        // Initialize editTextView from var passed from New_VC
        editTextView.text = email.body
        
        // Swipe/tap on screen to hide keyboard
        gesturesToHideKeyboard()
    }
    
    // MARK: - Send Methods
    @IBAction func sendNow(_ sender: Any) {
        sendEmail()
        if sendSuccess {
            performSegue(withIdentifier: "showSendNow", sender: nil)
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
            let controller = segue.destination as! SendLaterPicker_VC
            controller.to = to
            controller.from = from
            controller.email.subject = subjectTextField.text ?? ""
            controller.email.body = editTextView.text
        }
    }
    
    @IBAction func unwindFromSendLaterPicker(_ unwindSegue: UIStoryboardSegue) {
    }
    
    // MARK: - Helper Methods
    func gesturesToHideKeyboard() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tap)
        editTextView.keyboardDismissMode = .onDrag
    }
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
    
    func checkforEmptySubject() {
        let today = Date()
        let defaultSubject = DateFormatter()
        defaultSubject.dateFormat = "M/d/yy h:mma"
        
        if let subject = subjectTextField.text {
            if subject == "" {
                email.subject = "New Mailmo \(defaultSubject.string(from: today))"
            } else {
                email.subject = subject
            }
            print(email.subject)
        }
    }
    
    func sendEmail() {
        // Email String Object (w/ personalization parameters)
        checkforEmptySubject()
        let emailString = emailFormatter(to: to.email, toName: to.name ?? "",
                                         from: from.email, fromName: from.name ?? "",
                                         subject: email.subject, body: email.body,
                                         sendAt: nil)
        
        // Convert Email String -> UTF8 Data Object
        let emailData = emailString.data(using: .utf8)
        
        // Create SendGrid urlRequest
        var urlRequest = URLRequest(url: URL(string: "https://api.sendgrid.com/v3/mail/send")!,
                                 timeoutInterval: Double.infinity)
        // Add Authorization and Content-Type Values
        urlRequest.addValue("Bearer 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",
                         forHTTPHeaderField: "Authorization")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // "POST"/send emailData to SendGrid URL
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = emailData
        
        // Create shared SendGrid URLSession dataTask object
        let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            guard let data = data else {
                // Show error if no data received from SendGrid + suspend semaphore
                print(String(describing: error))
                self.semaphore.signal()
                return
            }
            // Suspend semaphore if data is received from SendGrid
            self.sendSuccess = true
            print(String(data: data, encoding: .utf8)!)
            self.semaphore.signal()
        }
        //  Resume task (post emailData to SendGrid) + start semaphore
        dataTask.resume()
        semaphore.wait()
    }
}

// MARK: - Text Field Delegate Methods
extension New_Edit_VC: UITextFieldDelegate {
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
extension New_Edit_VC: UITextViewDelegate {
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
            email.body = textWithBreaks
        }
//        print(mailmoBody)
        view.endEditing(true)
    }
}
