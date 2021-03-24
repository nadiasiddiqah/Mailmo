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
        let animationView = AnimationView()
        animationView.animation = Animation.named("sendLaterAnimation")
        sendLaterView.addSubview(animationView)
        
        animationView.translatesAutoresizingMaskIntoConstraints = false
        
        animationView.topAnchor.constraint(equalTo: sendLaterView.topAnchor).isActive = true
        animationView.bottomAnchor.constraint(equalTo: sendLaterView.bottomAnchor).isActive = true
        animationView.leftAnchor.constraint(equalTo: sendLaterView.leftAnchor).isActive = true
        animationView.rightAnchor.constraint(equalTo: sendLaterView.rightAnchor).isActive = true

        return animationView
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
            self.performSegue(withIdentifier: "backToMain", sender: nil)
        }
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
