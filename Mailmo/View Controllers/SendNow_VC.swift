//
//  SendNow_VC.swift
//  Mailmo
//
//  Created by Nadia Siddiqah on 3/23/21.
//

import UIKit
import Gifu
import TinyConstraints

class SendNow_VC: UIViewController {
    
    // MARK: - Lazy Variables
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
