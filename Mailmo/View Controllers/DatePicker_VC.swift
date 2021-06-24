//
//  DatePicker_VC.swift
//  Mailmo
//
//  Created by Nadia Siddiqah on 3/23/21.
//

import UIKit
import Firebase

class DatePicker_VC: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var selectDateAndTimeButton: UIButton!
    @IBOutlet weak var pickerView: UIView!
    @IBOutlet weak var buttonView: UIView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    
    // MARK: - Variables
    var initialDate = Date()
    var minDate = Date()
    var maxDate = Date()
    
    // Semaphore object (to ensure one thread accesses SendGrid at a time)
    var semaphore = DispatchSemaphore(value: 0)
    var sendSuccess = false
    
    // Passed from Edit_VC
    var to = EmailInfo(email: "", name: "")
    var from = EmailInfo(email: "", name: "")
    var email = SendGridData(subject: "", body: "", sendAt: 0)
    
    let firebaseAuth = Auth.auth()
    let firebaseData = Database.database().reference()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
    }
    
    // MARK: - Navigation
    @IBAction func nextButton(_ sender: Any) {
        nextAction()
    }
    
    @IBAction func selectDateAndTimeButton(_ sender: Any) {
        nextAction()
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
    func setupView() {
        selectDateAndTimeButton.titleLabel?.adjustsFontSizeToFitWidth = true
        
        pickerView.roundCorners([.topLeft, .topRight], radius: 10)
        buttonView.roundCorners([.bottomLeft, .bottomRight], radius: 10)
        
        setupDatePicker(startDate: initialDate)
    }
    
    func nextAction() {
        hudView(show: true, text: "Scheduling to send later...")
        calculateSendAt()
        sendEmail()
        
        if sendSuccess {
            postData()
            Utils.dismissHud(Utils.hud, text: "Scheduling to send later...", detailText: "", delay: 0.8)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                self.performSegue(withIdentifier: "showSendLater", sender: nil)
            }
        }
    }
    
    func hudView(show: Bool, text: String) {
        if show {
            Utils.hud.textLabel.text = text
            Utils.hud.detailTextLabel.text = nil
            Utils.hud.show(in: view, animated: true)
        }
    }
    
    func setupDatePicker(startDate: Date) {
        minDate = Calendar.autoupdatingCurrent.date(byAdding: .minute, value: 1, to: startDate)!
        maxDate = Calendar.autoupdatingCurrent.date(byAdding: .day, value: 3, to: startDate)!
        datePicker.minimumDate = minDate
        datePicker.maximumDate = maxDate
    }
    
    func checkforEmptySubject() {
        let formattedDate = DateFormatter()
        formattedDate.dateFormat = "MMM d, h:mm a"
        
        if email.subject == "" {
            email.subject = "🚀 Memo (\(formattedDate.string(from: datePicker.date)))"
        }
        print(email.subject)
    }
    
    func postData() {
        let sendTime = Utils.convertDateToString(datePicker.date)
        
        // Post data to Firebase
        if let uid = firebaseAuth.currentUser?.uid {
            firebaseData.child("posts/\(uid)").child(Utils.calculateSendTime()).setValue(["subject": email.subject,
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
        let emailString = Utils.emailFormatter(to: to.email, toName: to.name ?? "",
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
        let dataTask = URLSession.shared.dataTask(with: urlRequest) { [weak self] (data, response, error) in
            guard let strongSelf = self else { return }
            
            guard let data = data else {
                // Show error if no data received from SendGrid + suspend semaphore
                strongSelf.sendSuccess = false
                strongSelf.semaphore.signal()
                return
            }
            // Suspend semaphore if data is received from SendGrid
            strongSelf.sendSuccess = true
            print(String(data: data, encoding: .utf8)!)
            strongSelf.semaphore.signal()
        }
        //  Resume task (post emailData to SendGrid) + start semaphore
        dataTask.resume()
        semaphore.wait()
    }
    
    // MARK: - Error Handling Methods
    func handleInvalidAPI() {
        let alert = UIAlertController(title: "Error has occurred",
                                      message: "Mailmo email server is currently unavailable.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Back to Main", style: .cancel, handler: { [weak self] (_) in
            guard let strongSelf = self else { return }
            strongSelf.performSegue(withIdentifier: "unwindFromEditToMain", sender: nil)
        }))
        present(alert, animated: true, completion: nil)
    }
}
