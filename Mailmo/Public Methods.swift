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
import CryptoKit

// MARK: - Variables
let n_a = "Not Set"

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
        self.name = dictionary["name"] as? String ?? n_a
        self.email = dictionary["email"] as? String ?? n_a
        self.prefEmail = dictionary["prefEmail"] as? String ?? n_a
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

func isNameValid(_ name: String) -> Bool {
    guard name.count >= 2, name.count < 18 else { return false }

    let predicateTest = NSPredicate(format: "SELF MATCHES %@", "^(([^ ]?)(^[a-zA-Z].*[a-zA-Z]$)([^ ]?))$")
    return predicateTest.evaluate(with: name)
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


// MARK: - Generate Nonce for Apple Auth
func randomNonceString(length: Int = 32) -> String {
  precondition(length > 0)
  let charset: Array<Character> =
      Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
  var result = ""
  var remainingLength = length

  while remainingLength > 0 {
    let randoms: [UInt8] = (0 ..< 16).map { _ in
      var random: UInt8 = 0
      let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
      if errorCode != errSecSuccess {
        fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
      }
      return random
    }

    randoms.forEach { random in
      if remainingLength == 0 {
        return
      }

      if random < charset.count {
        result.append(charset[Int(random)])
        remainingLength -= 1
      }
    }
  }

  return result
}

func sha256(_ input: String) -> String {
  let inputData = Data(input.utf8)
  let hashedData = SHA256.hash(data: inputData)
  let hashString = hashedData.compactMap {
    return String(format: "%02x", $0)
  }.joined()

  return hashString
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

    @objc func fieldDidChangeInAlert() {
        if let email = textFields?[0].text,
            let action = actions.last {
            action.isEnabled = isEmailValid(email)
        }
    }
    
    @objc func bothFieldsDidChangeInAlert() {
        if let name = textFields?[0].text,
           let email = textFields?[1].text,
            let action = actions.last {
            
            action.isEnabled = isEmailValid(email) && isNameValid(name)
        }
    }
}

fileprivate let minimumHitArea = CGSize(width: 100, height: 100)

extension UIButton {
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // if the button is hidden/disabled/transparent it can't be hit
        if self.isHidden || !self.isUserInteractionEnabled || self.alpha < 0.01 { return nil }

        // increase the hit frame to be at least as big as `minimumHitArea`
        let buttonSize = self.bounds.size
        let widthToAdd = max(minimumHitArea.width - buttonSize.width, 0)
        let heightToAdd = max(minimumHitArea.height - buttonSize.height, 0)
        let largerFrame = self.bounds.insetBy(dx: -widthToAdd / 2, dy: -heightToAdd / 2)

        // perform hit test on larger frame
        return (largerFrame.contains(point)) ? self : nil
    }
}
