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
        subjectFormatter.dateFormat = "M/d/yy h:mma"
        
        if email.subject == "" {
            email.subject = "New Mailmo \(subjectFormatter.string(from: datePicker.date))"
        }
        print(email.subject)
    }
    
    func calculateSendAt() {
        let selectedDate = datePicker.date
        sendAt = Int(selectedDate.timeIntervalSince1970 / 60) * 60
    }
    
    func sendEmail() {
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
