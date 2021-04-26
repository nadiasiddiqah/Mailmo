//
//  SendLaterPicker_VC.swift
//  Mailmo
//
//  Created by Nadia Siddiqah on 3/23/21.
//

import UIKit

class SendLaterPicker_VC: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var datePicker: UIDatePicker!
    
    // MARK: - Variables
    var initialDate = Date()
    var sendAt = Int()
    var minDate = Date()
    var maxDate = Date()
    
    // Semaphore object (to ensure one thread accesses SendGrid at a time)
    var semaphore = DispatchSemaphore(value: 0)
    var sendSuccess = false
    
    // Passed from New_Edit_VC
    var to = EmailInfo(email: "", name: "")
    var from = EmailInfo(email: "", name: "")
    var email = EmailContent(subject: "", body: "")

    override func viewDidLoad() {
        super.viewDidLoad()
        datePicker.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
        setupDatePicker(startDate: initialDate)
    }
    
    // MARK: - Navigation
    @IBAction func nextButton(_ sender: Any) {
        calculateSendAt()
        sendEmail()
        
        if sendSuccess {
            updateHistory()
            performSegue(withIdentifier: "showSendLater", sender: nil)
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
    
    func updateHistory() {
        let sendTimeFormatter = DateFormatter()
        sendTimeFormatter.dateFormat = "M/d/yy h:mma"
        let sendTime = sendTimeFormatter.string(from: datePicker.date)
        
        scheduledEmails.append(CellInfo(statusColor: #colorLiteral(red: 1, green: 0.9015662074, blue: 0.8675737381, alpha: 1), statusIcon: UIImage(named: "sent_later")!,
                                   detailIcon: UIImage(named: "mail_later")!,
                                   subject: email.subject, body: email.body,
                                   sendTime: sendTime))
    }
    
    func calculateSendAt() {
        let selectedDate = datePicker.date
        sendAt = Int(selectedDate.timeIntervalSince1970 / 60) * 60
    }
    
    func sendEmail() {
        // Email String Object (w/ personalization parameters)
        checkforEmptySubject()
        let emailString = emailFormatter(to: to.email, toName: to.name ?? "",
                                         from: from.email, fromName: from.name ?? "",
                                         subject: email.subject, body: email.body,
                                         sendAt: sendAt)
        
        // Convert Email String -> UTF8 Data Object
        let emailData = emailString.data(using: .utf8)
        
        // Create SendGrid urlRequest
        var urlRequest = URLRequest(url: URL(string: "https://api.sendgrid.com/v3/mail/send")!,
                                 timeoutInterval: Double.infinity)
        // Check if sendGrid API key is broken
        guard let apiKey = ProcessInfo.processInfo.environment["sendGridAPI"] else {
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
