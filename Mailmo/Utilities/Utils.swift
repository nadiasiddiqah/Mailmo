//
//  Utilities.swift
//  Mailmo
//
//  Created by Nadia Siddiqah on 3/30/21.
//

import Foundation
import UIKit
import Lottie
import JGProgressHUD
import SwiftMessages

struct Utils {
    
    // MARK: - Variables
    static var hud: JGProgressHUD = {
        let hud = JGProgressHUD(style: .extraLight)
        hud.interactionType = .blockAllTouches
        return hud
    }()
    
    static let minimumHitArea = CGSize(width: 50, height: 50)

    // MARK: - Methods
    static func loadAnimation(fileName: String, loadingView: UIView) -> AnimationView {
        let animationView = AnimationView()
        animationView.animation = Animation.named(fileName)
        loadingView.addSubview(animationView)

        animationView.backgroundBehavior = .pauseAndRestore
        animationView.translatesAutoresizingMaskIntoConstraints = false

        animationView.topAnchor.constraint(equalTo: loadingView.topAnchor).isActive = true
        animationView.bottomAnchor.constraint(equalTo: loadingView.bottomAnchor).isActive = true
        animationView.leftAnchor.constraint(equalTo: loadingView.leftAnchor).isActive = true
        animationView.rightAnchor.constraint(equalTo: loadingView.rightAnchor).isActive = true

        return animationView
    }

    static func popupFormatter(body: String, iconText: String) {
        let msg = MessageView.viewFromNib(layout: .cardView)
        msg.configureTheme(.success)
        msg.configureDropShadow()
        
        msg.button?.isHidden = true
        msg.configureContent(title: "", body: body, iconText: iconText)
        
        var msgConfig = SwiftMessages.defaultConfig
        msgConfig.duration = .seconds(seconds: 1)
        msgConfig.presentationContext = .window(windowLevel: UIWindow.Level.normal)
        
        SwiftMessages.show(config: msgConfig, view: msg)
    }

    static func dismissHud(_ hud: JGProgressHUD, text: String, detailText: String, delay: TimeInterval) {
        hud.textLabel.text = text
        hud.detailTextLabel.text = detailText
        hud.dismiss(afterDelay: delay, animated: true)
    }
    
}

