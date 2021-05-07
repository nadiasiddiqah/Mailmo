//
//  SendLater_VC.swift
//  Mailmo
//
//  Created by Nadia Siddiqah on 3/23/21.
//

import UIKit
import Lottie

class SendLater_VC: UIViewController {

    // MARK: - Outlet Variables
    @IBOutlet weak var sendLaterView: UIView!
    
    // MARK: - Lazy Variables
    lazy var sendLaterAnimation: AnimationView = {
        loadAnimation(fileName: "sendLaterAnimation", loadingView: sendLaterView)
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
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        navigationController?.isNavigationBarHidden = true
        sendLaterAnimation.pause()
    }
    
    // MARK: - Methods
    func playAnimation() {
        sendLaterAnimation.play(fromProgress: 0, toProgress: 0.999, loopMode: .playOnce) { _ in
            self.performSegue(withIdentifier: "backToMain_Later", sender: nil)
        }
    }

}
