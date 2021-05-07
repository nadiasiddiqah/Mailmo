//
//  History_VC.swift
//  Mailmo
//
//  Created by Nadia Siddiqah on 3/23/21.
//

import UIKit

class History_VC: UIViewController {

    // MARK: - Variables
    var sentEmails = [FirebaseData]()
    var scheduledEmails = [FirebaseData]()
    var selectedRow: FirebaseData?
    var refreshTimer: Timer?
    
    // MARK: - Outlet Variables
    @IBOutlet weak var historyTableView: UITableView!
    @IBOutlet weak var refreshLabel: UILabel!
    
    // MARK: - View Controller Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkForHistory()
        
        // Manual refresh control
        historyTableView.refreshControl = UIRefreshControl()
        historyTableView.refreshControl?.addTarget(self, action: #selector(didPullToRefresh),
                                                   for: .valueChanged)
        
        // Automatic refresh control
        refreshTimer = Timer.scheduledTimer(timeInterval: 60,
                                            target: self, selector: #selector(refreshEveryMin),
                                            userInfo: nil, repeats: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        refreshTimer?.invalidate()
    }
    
    @objc private func refreshEveryMin() {
        // Re-fetch data
        print("refreshing data every minute")
        sortEmails()
        DispatchQueue.main.async {
            self.historyTableView.reloadData()
        }
    }
    
    @objc private func didPullToRefresh() {
        // Re-fetch data
        refreshTableView()
        
        DispatchQueue.main.async {
            self.historyTableView.refreshControl?.endRefreshing()
        }
    }
    
    func checkForHistory() {
        if allEmails.isEmpty {
            historyTableView.isHidden = true
            refreshLabel.isHidden = true
            noMailmoHistory()
        } else {
            sortEmails()
            showTableView()
        }
    }
    
    func refreshTableView() {
        print("refreshing data")
        
        sortEmails()
        DispatchQueue.main.async {
            self.historyTableView.refreshControl?.endRefreshing()
            self.historyTableView.reloadData()
        }
    }
    
    func sortEmails() {
        let timeNow = dateFormatter(date: Date())
        var sent = [FirebaseData]()
        var scheduled = [FirebaseData]()
        
        for email in allEmails {
            if timeNow >= email.sendAtString {
                sent.append(email)
            } else {
                scheduled.append(email)
            }
        }
        
        sentEmails = sent.sorted(by: { $0.sendAtString > $1.sendAtString })
        scheduledEmails = scheduled.sorted(by: { $0.sendAtString > $1.sendAtString })
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
    @IBAction func unwindFromNewToHistory(_ unwindSegue: UIStoryboardSegue) {
        print("go back to main")
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
        refreshLabel.isHidden = false
        historyTableView.tableHeaderView = refreshLabel
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
                selectedRow = scheduledEmails[indexPath.row]
            } else {
                selectedRow = sentEmails[indexPath.row]
            }
        } else {
            // Both sections have data
            selectedRow = indexPath.section == 0 ?
                scheduledEmails[indexPath.row] : sentEmails[indexPath.row]
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
        let cellInfo: FirebaseData
        if tableView.numberOfSections == 1 {
            // One section has data
            if sentEmails.isEmpty {
                cellInfo = scheduledEmails[indexPath.row]
            } else {
                cellInfo = sentEmails[indexPath.row]
            }
        } else {
            // Both sections have data
            cellInfo = indexPath.section == 0 ?
                scheduledEmails[indexPath.row] : sentEmails[indexPath.row]
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


