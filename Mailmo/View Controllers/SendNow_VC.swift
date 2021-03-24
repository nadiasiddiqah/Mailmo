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
        let gifImageView = GIFImageView()
        
        gifImageView.animate(withGIFNamed: "sendNowAnimation", loopCount: 1, preparationBlock: nil) {
            self.performSegue(withIdentifier: "backToMain", sender: nil)
        }

        return  gifImageView
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
    
    func playAnimation() {
        view.addSubview(sendNowAnimation)
        sendNowAnimation.centerInSuperview()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
