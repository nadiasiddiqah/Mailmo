//
//  Public Methods.swift
//  Mailmo
//
//  Created by Nadia Siddiqah on 3/30/21.
//

import Foundation
import UIKit
import Lottie
import JGProgressHUD
import SwiftMessages

// MARK: - Variables
var hud: JGProgressHUD = {
    let hud = JGProgressHUD(style: .extraLight)
    hud.interactionType = .blockAllTouches
    return hud
}()

var currentUserInfo: CurrentUser?

// MARK: - Classes / Structs
struct EmailInfo {
    var email: String
    var name: String?
}

struct SendGridData {
    var subject, body: String
    var sendAt: Int?
}

struct FirebaseData {
    var subject, body, sendAtString: String
}

struct CurrentUser {
    var uid, name, email, prefEmail: String
    
    init(uid: String, dictionary: [String: Any]) {
        self.uid = uid
        self.name = dictionary["name"] as? String ?? "No name set"
        self.email = dictionary["email"] as? String ?? "No email set"
        self.prefEmail = dictionary["prefEmail"] as? String ?? "No pref set"
    }
}

// MARK: - Methods
func calculateSendTime() -> String {
    let date = Date()
    let sendTime = Int(date.timeIntervalSince1970 * 60)
    return String(sendTime)
}

func isPasswordValid(_ password : String) -> Bool {

    let passwordTest = NSPredicate(format: "SELF MATCHES %@", "^(?=.*[a-z])(?=.*[$@$#!%*?&])[A-Za-z\\d$@$#!%*?&]{8,}")
    return passwordTest.evaluate(with: password)
}

func isEmailValid(_ email: String) -> Bool {
    
    let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

    let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
    return emailPred.evaluate(with: email)
}

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

func popupFormatter(body: String, iconText: String) {
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

func convertDateToString(_ date: Date) -> String {
    var sendTimeString = String()
    let sendTimeFormatter = DateFormatter()
    sendTimeFormatter.dateFormat = "M/d/yy h:mma"
    
    sendTimeString = sendTimeFormatter.string(from: date)
    
    return sendTimeString
}

func convertStringToUTC(_ string: String) -> Int {
    var sendTimeInt = Int()
    let sendTimeFormatter = DateFormatter()
    sendTimeFormatter.dateFormat = "M/d/yy h:mma"
    
    if let sendTimeDate = sendTimeFormatter.date(from: string) {
        sendTimeInt = Int(sendTimeDate.timeIntervalSince1970 / 60) * 60
    }
    
    return sendTimeInt
}

func dismissHud(_ hud: JGProgressHUD, text: String, detailText: String, delay: TimeInterval) {
    hud.textLabel.text = text
    hud.detailTextLabel.text = detailText
    hud.dismiss(afterDelay: delay, animated: true)
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

// MARK: - UIAlertController Extensions
extension UIAlertController {
    func pruneNegativeWidthConstraints() {
        for subView in self.view.subviews {
            for constraint in subView.constraints where constraint.debugDescription.contains("width == - 16") {
                subView.removeConstraint(constraint)
            }
        }
    }
}

extension UIAlertController {
    
    func isEmailValid(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }

    @objc func textDidChangeInAlert() {
        if let email = textFields?[0].text,
            let action = actions.last {
            action.isEnabled = isEmailValid(email)
        }
    }
}
