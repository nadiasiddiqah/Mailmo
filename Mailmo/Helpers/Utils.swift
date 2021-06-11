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
import CryptoKit

class Utils {
    // MARK: - Variables
    static let n_a = "Not Set"

    static var hud: JGProgressHUD = {
        let hud = JGProgressHUD(style: .extraLight)
        hud.interactionType = .blockAllTouches
        return hud
    }()
    
    static var currentUserInfo: CurrentUser?
    
    static let minimumHitArea = CGSize(width: 100, height: 100)
    
    // MARK: - Methods
    static func calculateSendTime() -> String {
        let date = Date()
        let sendTime = Int(date.timeIntervalSince1970 * 60)
        return String(sendTime)
    }

    static func isPasswordValid(_ password : String) -> Bool {

        let passwordTest = NSPredicate(format: "SELF MATCHES %@", "^(?=.*[a-z])(?=.*[$@$#!%*?&])[A-Za-z\\d$@$#!%*?&]{8,}")
        return passwordTest.evaluate(with: password)
    }

    static func isEmailValid(_ email: String) -> Bool {
        
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }

    static func isNameValid(_ name: String) -> Bool {
        guard name.count >= 2, name.count < 18 else { return false }

        let predicateTest = NSPredicate(format: "SELF MATCHES %@", "^(([^ ]?)(^[a-zA-Z].*[a-zA-Z]$)([^ ]?))$")
        return predicateTest.evaluate(with: name)
    }

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

    static func emailFormatter(to: String, toName: String,
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

    static func convertDateToString(_ date: Date) -> String {
        var sendTimeString = String()
        let sendTimeFormatter = DateFormatter()
        sendTimeFormatter.dateFormat = "M/d/yy h:mma"
        
        sendTimeString = sendTimeFormatter.string(from: date)
        
        return sendTimeString
    }

    static func convertStringToUTC(_ string: String) -> Int {
        var sendTimeInt = Int()
        let sendTimeFormatter = DateFormatter()
        sendTimeFormatter.dateFormat = "M/d/yy h:mma"
        
        if let sendTimeDate = sendTimeFormatter.date(from: string) {
            sendTimeInt = Int(sendTimeDate.timeIntervalSince1970 / 60) * 60
        }
        
        return sendTimeInt
    }

    static func dismissHud(_ hud: JGProgressHUD, text: String, detailText: String, delay: TimeInterval) {
        hud.textLabel.text = text
        hud.detailTextLabel.text = detailText
        hud.dismiss(afterDelay: delay, animated: true)
    }

    // MARK: - Generate Nonce for Apple Auth
    static func randomNonceString(length: Int = 32) -> String {
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

    static func sha256(_ input: String) -> String {
      let inputData = Data(input.utf8)
      let hashedData = SHA256.hash(data: inputData)
      let hashString = hashedData.compactMap {
        return String(format: "%02x", $0)
      }.joined()

      return hashString
    }


}

