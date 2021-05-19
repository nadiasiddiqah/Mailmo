//
//  SendLaterPicker_VC.swift
//  Mailmo
//
//  Created by Nadia Siddiqah on 3/23/21.
//

import UIKit
import Firebase

class SendLaterPicker_VC: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var datePicker: UIDatePicker!
    
    // MARK: - Variables
    var initialDate = Date()
    var minDate = Date()
    var maxDate = Date()
    
    // Semaphore object (to ensure one thread accesses SendGrid at a time)
    var semaphore = DispatchSemaphore(value: 0)
    var sendSuccess = false
    
    // Passed from New_Edit_VC
    var to = EmailInfo(email: "", name: "")
    var from = EmailInfo(email: "", name: "")
    var email = SendGridData(subject: "", body: "", sendAt: 0)
    
    let firebaseAuth = Auth.auth()
    let firebaseData = Database.database().reference()

    override func viewDidLoad() {
        super.viewDidLoad()
        datePicker.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
        setupDatePicker(startDate: initialDate)
    }
    
    // MARK: - Navigation
    @IBAction func nextButton(_ sender: Any) {
        hudView(show: true, text: "Scheduling to send later...")
        calculateSendAt()
        sendEmail()
        
        if sendSuccess {
            postData()
            dismissHud(hud, text: "Scheduling to send later...", detailText: "", delay: 0.8)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                self.performSegue(withIdentifier: "showSendLater", sender: nil)
            }
        }
    }
    
    // MARK: - Action Methods
    
    @IBAction func updateDatePicker(_ sender: UIDatePicker) {
        let currentDate = Date()
        if currentDate > minDate {
            setupDatePicker(startDate: currentDate)
            sender.setDate(minDate, animated: true)
        }
    }
    
    // MARK: - Helper Methods
    func hudView(show: Bool, text: String) {
        if show {
            hud.textLabel.text = text
            hud.detailTextLabel.text = nil
            hud.show(in: view, animated: true)
        }
    }
    
    func setupDatePicker(startDate: Date) {
        minDate = Calendar.autoupdatingCurrent.date(byAdding: .minute, value: 1, to: startDate)!
        maxDate = Calendar.autoupdatingCurrent.date(byAdding: .day, value: 3, to: startDate)!
        datePicker.minimumDate = minDate
        datePicker.maximumDate = maxDate
    }
    
    func checkforEmptySubject() {
        let subjectFormatter = DateFormatter()
        subjectFormatter.dateFormat = "M-d h:mm"
        
        if email.subject == "" {
            email.subject = "Memo \(subjectFormatter.string(from: datePicker.date))"
        }
        print(email.subject)
    }
    
    func postData() {
        let sendTime = convertDateToString(datePicker.date)
        
        // Post data to Firebase
        if let uid = firebaseAuth.currentUser?.uid {
            print("Successfully posted data to Firebase")
            firebaseData.child("posts/\(uid)").child(calculateSendTime()).setValue(["subject": email.subject,
                                                                                    "body": email.body,
                                                                                    "sendAtString": sendTime])
        }
    }
    
    func calculateSendAt() {
        let selectedDate = datePicker.date
        email.sendAt = Int(selectedDate.timeIntervalSince1970 / 60) * 60
    }
    
    func sendEmail() {
        // Email String Object (w/ personalization parameters)
        checkforEmptySubject()
        let emailString = emailFormatter(to: to.email, toName: to.name ?? "",
                                         from: from.email, fromName: from.name!,
                                         subject: email.subject, body: email.body,
                                         sendAt: email.sendAt)
        
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
        //  Resume task (post emailData to SendGrid) + start semaphore
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
