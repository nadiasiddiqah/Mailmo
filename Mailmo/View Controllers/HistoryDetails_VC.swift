//
//  HistoryDetails_VC.swift
//  Mailmo
//
//  Created by Nadia Siddiqah on 3/24/21.
//

import UIKit

class HistoryDetails_VC: UIViewController {
    
    // MARK: - Variables
    // Passed from HistoryVC
    var rowDetail: FirebaseData?
    
    // MARK: - Outlets
    @IBOutlet weak var sendAtLabel: UILabel!
    @IBOutlet weak var statusIcon: UIImageView!
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var bodyTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
    }
    
    // MARK: - Helper Methods
    func setupView() {
        if let row = rowDetail {
            let timeNow = dateFormatter(date: Date())
            
            if timeNow >= row.sendAtString {
                sendAtLabel.text = "Sent: \(row.sendAtString)"
                statusIcon.image = UIImage(named: "sent_now")
            } else {
                sendAtLabel.text = "Scheduled: \(row.sendAtString)"
                statusIcon.image = UIImage(named: "sent_later")
            }
            
            subjectLabel.text = row.subject
            bodyTextView.text = row.body
        }
    }
}

