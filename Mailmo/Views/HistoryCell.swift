//
//  HistoryCell.swift
//  Mailmo
//
//  Created by Nadia Siddiqah on 4/21/21.
//

import UIKit

class HistoryCell: UITableViewCell {
    
    // MARK: - Outlet Variables
    @IBOutlet weak var cellBackgroundView: UIView!
    @IBOutlet weak var statusImage: UIImageView!
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var sendAtLabel: UILabel!

    // MARK: - Helper Methods
    func configureHistoryCell(info: FirebaseData) {
        let timeNow = Int(Date().timeIntervalSince1970 / 60) * 60
        let sendAtInt = Utils.convertStringToUTC(info.sendAtString)
        
        if timeNow >= sendAtInt {
            // If timeNow >= sendAtString -> email is sent
            cellBackgroundView.backgroundColor = #colorLiteral(red: 0.8039215686, green: 0.9450980392, blue: 1, alpha: 1)
            statusImage.image = UIImage(named: "sent_now")!
        } else {
            cellBackgroundView.backgroundColor = #colorLiteral(red: 1, green: 0.9015662074, blue: 0.8675737381, alpha: 1)
            statusImage.image = UIImage(named: "sent_later")
        }
        
        subjectLabel.text = info.subject
        sendAtLabel.text = info.sendAtString
    }
    
}

