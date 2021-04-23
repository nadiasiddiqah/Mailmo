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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
        welcomeAnimation.play(fromProgress: 0, toProgress: 1, loopMode: .loop, completion: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        welcomeAnimation.pause()
    }
    
    // MARK: - Navigation Methods
    @IBAction func unwindFromEditToMain(_ unwindSegue: UIStoryboardSegue) {
    }
    
    @IBAction func unwindFromHistoryToMain(_ unwindSegue: UIStoryboardSegue) {
    }
    
    @IBAction func unwindFromNewToMain(_ unwindSegue: UIStoryboardSegue) {
    }
}
