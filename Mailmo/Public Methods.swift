//
//  Public Methods.swift
//  Mailmo
//
//  Created by Nadia Siddiqah on 3/30/21.
//

import Foundation
import UIKit
import Lottie

func loadAnimation(fileName: String, loadingView: UIView) -> AnimationView {
    let animationView = AnimationView()
    animationView.animation = Animation.named(fileName)
    loadingView.addSubview(animationView)

    animationView.translatesAutoresizingMaskIntoConstraints = false

    animationView.topAnchor.constraint(equalTo: loadingView.topAnchor).isActive = true
    animationView.bottomAnchor.constraint(equalTo: loadingView.bottomAnchor).isActive = true
    animationView.leftAnchor.constraint(equalTo: loadingView.leftAnchor).isActive = true
    animationView.rightAnchor.constraint(equalTo: loadingView.rightAnchor).isActive = true

    return animationView
}
