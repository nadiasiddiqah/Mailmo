//
//  New_Permitted_VC.swift
//  Mailmo
//
//  Created by Nadia Siddiqah on 3/22/21.
//

import UIKit
import Lottie

class New_Permitted_VC: UIViewController {
    
    // MARK: - Variables
    var tappedToStop = false

    // MARK: - Outlet Variables
    @IBOutlet weak var dotsView: UIImageView!
    @IBOutlet weak var voiceView: UIImageView!
    @IBOutlet weak var recordButton: UIButton!
    
    
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
    
    lazy var recordAnimation: AnimationView = {
        let animationView = AnimationView()
        animationView.animation = Animation.named("recordAnimation")
        animationView.frame = recordButton.bounds
        recordButton.addSubview(animationView)
        
        animationView.translatesAutoresizingMaskIntoConstraints = false
        
        animationView.topAnchor.constraint(equalTo: recordButton.topAnchor).isActive = true
        animationView.bottomAnchor.constraint(equalTo: recordButton.bottomAnchor).isActive = true
        animationView.leftAnchor.constraint(equalTo: recordButton.leftAnchor).isActive = true
        animationView.rightAnchor.constraint(equalTo: recordButton.rightAnchor).isActive = true

        return animationView
    }()
    
    lazy var voiceAnimation: AnimationView = {
        let animationView = AnimationView()
        animationView.animation = Animation.named("voiceAnimation")
        voiceView.addSubview(animationView)
        
        animationView.translatesAutoresizingMaskIntoConstraints = false
        
        animationView.topAnchor.constraint(equalTo: voiceView.topAnchor).isActive = true
        animationView.bottomAnchor.constraint(equalTo: voiceView.bottomAnchor).isActive = true
        animationView.leftAnchor.constraint(equalTo: voiceView.leftAnchor).isActive = true
        animationView.rightAnchor.constraint(equalTo: voiceView.rightAnchor).isActive = true

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
    
    // MARK: - Action Methods
    
    // MARK: - Methods
    func playAnimation() {
        dotsAnimation.play(fromProgress: 0, toProgress: 1, loopMode: .loop, completion: nil)
        recordAnimation.play(fromProgress: 0, toProgress: 1, loopMode: .loop, completion: nil)
        voiceAnimation.animationSpeed = 0.5
        voiceAnimation.play(fromProgress: 0, toProgress: 1, loopMode: .loop, completion: nil)
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
