//
//  SendEmail_VM.swift
//  Mailmo
//
//  Created by Nadia Siddiqah on 6/28/21.
//

import Foundation

class SendEmail_VM {
    
    static func calculateSendTime() -> String {
        let date = Date()
        let sendTime = Int(date.timeIntervalSince1970 * 60)
        return String(sendTime)
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
    
    static func isPasswordValid(_ password : String) -> Bool {

        let passwordTest = NSPredicate(format: "SELF MATCHES %@", "^(?=.*[a-z])(?=.*[$@$#!%*?&])[A-Za-z\\d$@$#!%*?&]{8,}")
        return passwordTest.evaluate(with: password)
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
}
