//
//  SendNow_VC.swift
//  Mailmo
//
//  Created by Nadia Siddiqah on 3/23/21.
//

import UIKit
import Gifu
import TinyConstraints
import Firebase

class SendNow_VC: UIViewController {
    
    // MARK: - Variables
    let firebaseAuth = Auth.auth()
    let firebaseData = Database.database().reference()
    var databaseHandler: DatabaseHandle?
    
    lazy var sendNowAnimation: GIFImageView = {
        let gif = GIFImageView()
        
        gif.animate(withGIFNamed: "sendNowAnimation", loopCount: 1, preparationBlock: nil) {
            self.performSegue(withIdentifier: "backToMain_Now", sender: self)
        }

        return gif
    }()

    // MARK: - View Controller Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        playAnimation()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "backToMain_Now" {
            let controller = segue.destination as! Main_VC
            controller.showStatusPopup = true
            controller.statusText = "Mailmo successfully sent!"
            controller.iconText = ["✅", "🙌🏽", "👍🏾", "✉️"].randomElement()!
        }
    }
    
    // MARK: - Methods
    func playAnimation() {
        view.addSubview(sendNowAnimation)
        sendNowAnimation.centerInSuperview()
    }

}

func setupInitialUI() {
//    self.tutorialView.alpha = 0.0
    
    // Find noOfEmails
//        if let uid = firebaseAuth.currentUser?.uid {
//            userID = uid
//            databaseHandler = firebaseData.child("posts/\(userID)").observe(.value, with: { (snapshot) in
//                guard snapshot.exists() else {
//                    self.noOfEmails = 0
//                    return
//                }
//                self.noOfEmails = Int(snapshot.childrenCount)
//            })
//            print(noOfEmails)
//        }
    
    // Indicate pulsing button based on noOfEmails
//        if noOfEmails == 0 && self.showTutorialView == false {
//            // Show pulsing newButton + all buttonHints (noOfEmails = 0)
//            UIView.animate(withDuration: 0.6) {
//                self.showPulsingButton(button: self.newButton, color: #colorLiteral(red: 0.9423340559, green: 0.3914486766, blue: 0.2496597767, alpha: 1))
//
//                self.newInfo.alpha = 1.0
//                self.historyInfo.alpha = 1.0
//                self.settingsInfo.alpha = 1.0
//            }
//        } else if noOfEmails == 1 {
//            // Show history buttonHint (noOfEmails = 1)
//            UIView.animate(withDuration: 0.6) {
//
//                self.newInfo.alpha = 0.0
//                self.historyInfo.alpha = 1.0
//                self.settingsInfo.alpha = 0.0
//            }
//        } else {
//            // Show no buttonHints (noOfEmails > 1)
//            self.newInfo.alpha = 0.0
//            self.historyInfo.alpha = 0.0
//            self.settingsInfo.alpha = 0.0
//        }
}
