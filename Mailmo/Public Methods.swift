//
//  Public Methods.swift
//  Mailmo
//
//  Created by Nadia Siddiqah on 3/30/21.
//

import Foundation
import UIKit
import Lottie

// MARK: - Variables

struct EmailInfo {
    var email: String
    var name: String?
}

struct EmailContent {
    var subject: String
    var body: String
}

// MARK: - Methods
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

func emailFormatter(to: String, toName: String,
                    from: String, fromName: String,
                    subject: String, body: String,
                    sendAt: Int?) -> String {
    // TO-DO: Condense by putting first email into variable and adding if sendAt != nil statement
    var email = ""
    if sendAt == nil {
        email = "{ \"personalizations\": " +
            "[{ \"to\": [{ \"email\": \"\(to)\", \"name\": \"\(toName)\" }] } ], " +
            "\"from\": { \"email\": \"\(from)\", \"name\": \"\(fromName)\" }, " +
            "\"subject\": \"\(subject)\", " +
            "\"content\": [{ \"type\": \"text/html\", " +
            "\"value\": \"\(body)\" }] }"
    } else {
        email = "{ \"personalizations\": " +
            "[{ \"to\": [{ \"email\": \"\(to)\", \"name\": \"\(toName)\" }] } ], " +
            "\"from\": { \"email\": \"\(from)\", \"name\": \"\(fromName)\" }, " +
            "\"subject\": \"\(subject)\", " +
            "\"content\": [{ \"type\": \"text/html\", " +
            "\"value\": \"\(body)\" }], " +
            "\"send_at\": \(sendAt!) }"
    }
    
    return email
}


// MARK: - UIView Extensions
extension UIView {
    func fadeTransition(_ duration: CFTimeInterval) {
        let animation = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name:
            CAMediaTimingFunctionName.easeInEaseOut)
        animation.type = CATransitionType.fade
        animation.duration = duration
        layer.add(animation, forKey: CATransitionType.fade.rawValue)
    }
}
