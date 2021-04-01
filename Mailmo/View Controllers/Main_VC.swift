//
//  Main_VC.swift
//  Mailmo App
//
//  Created by Nadia Siddiqah on 3/17/21.
//

import UIKit
import Lottie

class Main_VC: UIViewController {
    
    // MARK: - Outlet Variables
    @IBOutlet weak var welcomeIcon: UIImageView!
    
    // MARK: - Lazy Variables
    lazy var welcomeAnimation: AnimationView = {
        loadAnimation(fileName: "welcomeAnimation", loadingView: welcomeIcon)
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
        welcomeAnimation.pause()
    }
    
    // MARK: - Methods
    func playAnimation() {
        welcomeAnimation.play(fromProgress: 0, toProgress: 1, loopMode: .loop, completion: nil)
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
