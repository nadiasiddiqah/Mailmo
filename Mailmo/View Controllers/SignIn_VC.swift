//
//  SignIn_VC.swift
//  Mailmo App
//
//  Created by Nadia Siddiqah on 3/16/21.
//

import UIKit
import Lottie

class SignIn_VC: UIViewController {
    
    enum MailmoAnimationFrames: CGFloat {
        case start = 5
        case narrow = 15
        case firing = 25
    }
    
    // MARK: - Lazy Variables
    lazy var mailmoAnimation: AnimationView = {
        loadAnimation(fileName: "mailmoIconAnimation", loadingView: mailmoIcon)
    }()
    
    // MARK: - Outlet Variables
    @IBOutlet weak var mailmoIcon: UIImageView!

    // MARK: - View Controller Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        playAnimation()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        mailmoAnimation.pause()
    }
    
    // MARK: - Methods
    func playAnimation() {
        mailmoAnimation.animationSpeed = 0.25
        mailmoAnimation.play(fromFrame: MailmoAnimationFrames.start.rawValue, toFrame: MailmoAnimationFrames.firing.rawValue, loopMode: .none) { _ in
            self.mailmoAnimation.animationSpeed = 0.15
            self.mailmoAnimation.play(fromFrame: MailmoAnimationFrames.firing.rawValue, toFrame: MailmoAnimationFrames.narrow.rawValue, loopMode: .autoReverse, completion: nil)
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
