//
//  Settings_VC.swift
//  Mailmo
//
//  Created by Nadia Siddiqah on 3/24/21.
//

import UIKit

class Settings_VC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    // MARK: - Navigation
     @IBAction func backToMain(_ sender: Any) {
        navigationController?.popViewController(animated: true)
     }
     
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }

}
