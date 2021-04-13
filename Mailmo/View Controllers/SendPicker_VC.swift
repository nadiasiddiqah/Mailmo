//
//  SendPicker_VC.swift
//  Mailmo
//
//  Created by Nadia Siddiqah on 3/23/21.
//

import UIKit

class SendPicker_VC: UIViewController {
    
    // Passed From New_Edit_VC
    var mailmoSubject = String()
    var mailmoContent = String()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    // MARK: - Navigation
    @IBAction func backToNewEdit(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//    }

}
