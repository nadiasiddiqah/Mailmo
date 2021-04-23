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
    @IBOutlet weak var sendTimeLabel: UILabel!

    // MARK: - Helper Methods
    func configureHistoryCell(info: CellInfo) {
        cellBackgroundView.backgroundColor = info.statusColor
        statusImage.image = info.statusIcon
        subjectLabel.text = info.subject
        sendTimeLabel.text = info.sendTime
    }
    
}
