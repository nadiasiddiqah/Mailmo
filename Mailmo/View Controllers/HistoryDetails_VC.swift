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
    var rowDetail: CellInfo?
    
    // MARK: - Outlets
    @IBOutlet weak var sentTimeLabel: UILabel!
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
            if row.statusIcon == UIImage(named: "mail_now") {
                sentTimeLabel.text = "Sent: \(row.sendTime)"
            } else {
                sentTimeLabel.text = "Scheduled: \(row.sendTime)"
            }
            statusIcon.image = row.detailIcon
            subjectLabel.text = row.subject
            bodyTextView.text = row.body
        }
    }

}
