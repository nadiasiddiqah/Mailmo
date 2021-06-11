//
//  History_VC.swift
//  Mailmo
//
//  Created by Nadia Siddiqah on 3/23/21.
//

import UIKit
import Firebase

class History_VC: UIViewController {

    // MARK: - Variables
    var allEmails = [FirebaseData]()
    var sentEmails = [FirebaseData]()
    var scheduledEmails = [FirebaseData]()
    var selectedRow: FirebaseData?
    var refreshTimer: Timer?
    
    let firebaseAuth = Auth.auth()
    let firebaseData = Database.database().reference()
    var databaseHandler: DatabaseHandle?
    var userID = String()
    
    // MARK: - Outlet Variables
    @IBOutlet weak var historyTableView: UITableView!
    @IBOutlet weak var refreshLabel: UILabel!
    
    // MARK: - View Controller Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkIfDataExists()
    }
    
    // MARK: - Navigation Methods
    @IBAction func unwindFromNewToHistory(_ unwindSegue: UIStoryboardSegue) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func unwindFromHistoryDetails(_ unwindSegue: UIStoryboardSegue) {
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showHistoryDetail" {
            let controller = segue.destination as! HistoryDetails_VC
            controller.rowDetail = selectedRow
        } else if segue.identifier == "unwindFromHistoryToMain" {
            let controller = segue.destination as! Main_VC
            if controller.noOfEmails == 1 {
                controller.stopHistoryPulse = true
            }
        }
    }
    
    // MARK: - Helper Methods
    
    // Executes when a child is added under Posts
    func checkIfDataExists() {
        if let uid = firebaseAuth.currentUser?.uid {
            userID = uid
            databaseHandler = firebaseData.child("posts/\(uid)").observe(.value, with: { [weak self] (snapshot) in
                guard let strongSelf = self else { return }
                
                guard snapshot.exists() else {
                    DispatchQueue.main.async {
                        strongSelf.noMailmoHistory()
                    }
                    return
                }
                strongSelf.fetchData()
            })
        }
    }
    
    func fetchData() {
        databaseHandler = firebaseData.child("posts/\(userID)").observe(.childAdded, with: { [weak self] (snapshot) in
            guard let strongSelf = self else { return }
            
            // If snapshot exists, append childSnapshot to allEmails
            if let subject = snapshot.childSnapshot(forPath: "subject").value as? String,
               let body = snapshot.childSnapshot(forPath: "body").value as? String,
               let sendAtString = snapshot.childSnapshot(forPath: "sendAtString").value as? String {
                strongSelf.allEmails.append(FirebaseData(subject: subject, body: body, sendAtString: sendAtString))
            }

            // Sort emails, show table view, and start refeshing
            strongSelf.sortEmails()
            strongSelf.showTableView()
            strongSelf.startRefreshing()
        })
    }
    
    func noMailmoHistory() {
        // Hide table view and refresh label
        self.historyTableView.isHidden = true
        self.refreshLabel.isHidden = true
        
        // Show alert
        let alert = UIAlertController(title: "No Mailmo History",
                                      message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Record Mailmo", style: .default, handler: { [weak self] (_) in
            guard let strongSelf = self else { return }
            strongSelf.performSegue(withIdentifier: "showNew", sender: nil)
        }))
        alert.addAction(UIAlertAction(title: "Back to Main", style: .cancel, handler: { [weak self] (_) in
            guard let strongSelf = self else { return }
            strongSelf.performSegue(withIdentifier: "unwindFromHistoryToMain", sender: nil)
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func sortEmails() {
        // Convert timeNow to UTC
        let timeNow = Int(Date().timeIntervalSince1970 / 60) * 60
        
        var sent = [FirebaseData]()
        var scheduled = [FirebaseData]()
        
        for email in allEmails {
            // Convert each email's sendAtString to UTC
            let sendAtInt = Utils.convertStringToUTC(email.sendAtString)
            
            // Compare each email's UTC vs timeNow's UTC
            if timeNow >= sendAtInt {
                sent.append(email)
            } else {
                scheduled.append(email)
            }
        }
        
        sentEmails = sent.sorted(by: { Utils.convertStringToUTC($0.sendAtString) > Utils.convertStringToUTC($1.sendAtString) })
        scheduledEmails = scheduled.sorted(by: { Utils.convertStringToUTC($0.sendAtString) > Utils.convertStringToUTC($1.sendAtString) })
    }
    
    func showTableView() {
        historyTableView.delegate = self
        historyTableView.dataSource = self
        refreshLabel.isHidden = false
        historyTableView.tableHeaderView = refreshLabel
    }
    
    func startRefreshing() {
        historyTableView.reloadData()
        historyTableView.refreshControl = UIRefreshControl()
        historyTableView.refreshControl?.addTarget(self, action: #selector(didPullToRefresh),
                                                   for: .valueChanged)
    }
    
    func refreshTableView() {
        
        sortEmails()
        DispatchQueue.main.async {
            self.historyTableView.refreshControl?.endRefreshing()
            self.historyTableView.reloadData()
        }
    }
    
    // MARK: - Obj-C Methods
    @objc private func didPullToRefresh() {
        // Re-fetch data
        refreshTableView()
        
        DispatchQueue.main.async {
            self.historyTableView.refreshControl?.endRefreshing()
        }
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


