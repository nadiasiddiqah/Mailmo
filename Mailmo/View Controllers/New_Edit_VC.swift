//
//  New_Edit_VC.swift
//  Mailmo
//
//  Created by Nadia Siddiqah on 3/23/21.
//

import UIKit

class New_Edit_VC: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var subjectTextView: UITextField!
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
        subjectFormatter.dateFormat = "M/d/yy H:mma"
        editTextView.text = editText
        
        if editTextView.text == "" {
            sendToEmail.isEnabled = false
            sendToEmail_iCloud.isEnabled = false
        } else {
            sendToEmail.isEnabled = true
            sendToEmail_iCloud.isEnabled = true
        }
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
            controller.mailmoSubject = subjectTextView.text ?? "New Mailmo \(subjectFormatter.string(from: today))"
            controller.mailmoContent = editTextView.text
        }
    }
    
}
