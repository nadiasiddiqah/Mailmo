//
//  History_VC.swift
//  Mailmo
//
//  Created by Nadia Siddiqah on 3/23/21.
//

import UIKit

class History_VC: UIViewController {

    // MARK: - Variables
    var sortedSentEmails = [CellInfo]()
    var sortedScheduledEmails = [CellInfo]()
    var selectedRow: CellInfo?
    
    // MARK: - Outlet Variables
    @IBOutlet weak var historyTableView: UITableView!
    
    // MARK: - View Controller Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if sentEmails.isEmpty && scheduledEmails.isEmpty {
            historyTableView.isHidden = true
            noMailmoHistory()
            
            
//            let noMailmo = UILabel()
//            noMailmo.text = "No Mailmo History"
//            view.addSubview(noMailmo)
//            noMailmo.centerInSuperview()
        } else {
            showTableView()
        }
    }
    
    func noMailmoHistory() {
        let alert = UIAlertController(title: "No Mailmo History",
                                      message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Record Mailmo", style: .default, handler: { (_) in
            self.performSegue(withIdentifier: "showNew", sender: nil)
        }))
        alert.addAction(UIAlertAction(title: "Back to Main", style: .cancel, handler: { (_) in
            self.performSegue(withIdentifier: "unwindFromHistoryToMain", sender: nil)
        }))
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Navigation Methods
    @IBAction func backToMain(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func unwindFromNewToHistory(_ unwindSegue: UIStoryboardSegue) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func unwindFromHistoryDetails(_ unwindSegue: UIStoryboardSegue) {
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showHistoryDetail" {
            let controller = segue.destination as! HistoryDetails_VC
            controller.rowDetail = selectedRow
        }
    }
    
    func showTableView() {
        historyTableView.delegate = self
        historyTableView.dataSource = self
    }
}

// MARK: - Table View Delegate Methods
extension History_VC: UITableViewDelegate {
    // Number of Sections
    func numberOfSections(in tableView: UITableView) -> Int {
        if sentEmails.isEmpty || scheduledEmails.isEmpty {
            // One section has data
            return 1
        }
        // Both sections have data
        return 2
    }

    // Number of Rows
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        
        // One section has data
        if scheduledEmails.isEmpty {
            return sentEmails.count
        } else if sentEmails.isEmpty {
            return scheduledEmails.count
        }
        
        // Both sections have data
        if section == 0 {
            return scheduledEmails.count
        }
        return sentEmails.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.numberOfSections == 1 {
            // One section has data
            if sentEmails.isEmpty {
                selectedRow = sortedScheduledEmails[indexPath.row]
            } else {
                selectedRow = sortedSentEmails[indexPath.row]
            }
        } else {
            // Both sections have data
            selectedRow = indexPath.section == 0 ?
                sortedScheduledEmails[indexPath.row] : sortedSentEmails[indexPath.row]
        }
        
        performSegue(withIdentifier: "showHistoryDetail", sender: nil)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - Table View Data Source Methods
extension History_VC: UITableViewDataSource {
    // Header for Each Section
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // Only one section has data
        if tableView.numberOfSections == 1 {
            if sentEmails.isEmpty {
                return "Scheduled Mailmo"
            }
            return "Sent Mailmo"
        }
        
        // Both sections have data
        if section == 0 {
            return "Scheduled Mailmo"
        }
        return "Sent Mailmo"
    }
    
    // Info for Each Cell
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Draw each cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "historyCell",
                                                 for: indexPath) as! HistoryCell
        cell.selectionStyle = .none

        // Sort by Recent to Oldest + Info for each cell
        let cellInfo: CellInfo
        if tableView.numberOfSections == 1 {
            // One section has data
            if sentEmails.isEmpty {
                sortedScheduledEmails = scheduledEmails.sorted(by: { $0.sendTime > $1.sendTime })
                cellInfo = sortedScheduledEmails[indexPath.row]
            } else {
                sortedSentEmails = sentEmails.sorted(by: { $0.sendTime > $1.sendTime })
                cellInfo = sortedSentEmails[indexPath.row]
            }
        } else {
            // Both sections have data
            sortedScheduledEmails = scheduledEmails.sorted(by: { $0.sendTime > $1.sendTime })
            sortedSentEmails = sentEmails.sorted(by: { $0.sendTime > $1.sendTime })

            cellInfo = indexPath.section == 0 ?
                sortedScheduledEmails[indexPath.row] : sortedSentEmails[indexPath.row]
        }
        
        // Configure each cell
        cell.configureHistoryCell(info: cellInfo)
        
        return cell
    }
    
    // Selected Cell
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.contentView.layer.masksToBounds = true
        cell?.contentView.layer.cornerRadius = 15
        cell?.contentView.backgroundColor = #colorLiteral(red: 0.9685675502, green: 0.9686638713, blue: 0.9809786677, alpha: 1)
    }
    
    // Unselect Cell
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { (_) in
            cell?.contentView.backgroundColor = .clear
        }
    }
}


