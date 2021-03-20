//
//  New_AskPermission_VC.swift
//  Mailmo
//
//  Created by Nadia Siddiqah on 3/19/21.
//

import UIKit
import Lottie

class New_AskPermission_VC: UIViewController {
    
    // MARK: - Outlet Variables
    @IBOutlet weak var dotsView: UIImageView!
    
    // MARK: - Lazy Variables
    lazy var dotsAnimation: AnimationView = {
        let animationView = AnimationView()
        animationView.animation = Animation.named("dotsAnimation")
        animationView.frame = dotsView.bounds
        dotsView.addSubview(animationView)
        
        animationView.translatesAutoresizingMaskIntoConstraints = false
        
        animationView.topAnchor.constraint(equalTo: dotsView.topAnchor).isActive = true
        animationView.bottomAnchor.constraint(equalTo: dotsView.bottomAnchor).isActive = true
        animationView.leftAnchor.constraint(equalTo: dotsView.leftAnchor).isActive = true
        animationView.rightAnchor.constraint(equalTo: dotsView.rightAnchor).isActive = true

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
        dotsAnimation.pause()
    }
    
    // MARK: - Methods
    func playAnimation() {
        dotsAnimation.play(fromProgress: 0, toProgress: 1, loopMode: .loop, completion: nil)
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
