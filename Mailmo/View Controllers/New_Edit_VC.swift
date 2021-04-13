//
//  New_Edit_VC.swift
//  Mailmo
//
//  Created by Nadia Siddiqah on 3/23/21.
//

import UIKit

class New_Edit_VC: UIViewController, UITextFieldDelegate, UITextViewDelegate {
    
    // MARK: - Outlets
    @IBOutlet weak var subjectTextField: UITextField!
    @IBOutlet weak var editTextView: UITextView!
    @IBOutlet weak var sendToEmail: UIButton!
    @IBOutlet weak var sendToEmail_iCloud: UIButton!
    
    // MARK: - Variables
    var today = Date()
    var subjectFormatter = DateFormatter()
    
    // Passed From New_VC
    var editText = String()
    var subjectText = String()
    
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
        
        // Initialize subject formatter (if subjectTextField blank)
        subjectFormatter.dateFormat = "M/d/yy H:mma"
        
        // Initialize editTextView from var passed from New_VC
        editTextView.text = editText
        
        // Swipe/tap on screen to hide keyboard
        gesturesToHideKeyboard()
    }
    
    // MARK: - Send Methods
    @IBAction func emailButton(_ sender: Any) {
        performSegue(withIdentifier: "showSendPicker", sender: nil)
    }
    
    @IBAction func email_iCloudButton(_ sender: Any) {
        performSegue(withIdentifier: "showSendPicker", sender: nil)
    }
    
    // MARK: - Navigation Methods
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSendPicker" {
            let controller = segue.destination as! SendPicker_VC
            controller.mailmoSubject = subjectTextField.text ?? "New Mailmo \(subjectFormatter.string(from: today))"
            controller.mailmoContent = editTextView.text
            print("subjectFormatter: \(String(describing: subjectTextField.text))")
            print("editTextView: \(String(describing: editTextView.text))")
        }
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
    
    // MARK: - Text Field Delegate Methods
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let enteredSubject = subjectTextField.text {
            subjectText = enteredSubject
        }
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Ends all editing
        view.endEditing(true)
        return true
    }
    
    // MARK: - Text View Delegate Methods
    func textViewDidChange(_ textView: UITextView) {
        if editTextView.text == "" {
            sendToEmail.isEnabled = false
            sendToEmail_iCloud.isEnabled = false
        } else {
            sendToEmail.isEnabled = true
            sendToEmail_iCloud.isEnabled = true
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if let enteredText = editTextView.text {
            editText = enteredText
        }
        view.endEditing(true)
    }
}
