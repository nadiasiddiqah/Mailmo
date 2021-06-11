//
//  CurrentUser.swift
//  Mailmo
//
//  Created by Nadia Siddiqah on 6/10/21.
//

import Foundation
import UIKit

struct CurrentUser {
    
    var uid, name, email, prefEmail: String
    
    init(uid: String, dictionary: [String: Any]) {
        self.uid = uid
        self.name = dictionary["name"] as? String ?? Utils.n_a
        self.email = dictionary["email"] as? String ?? Utils.n_a
        self.prefEmail = dictionary["prefEmail"] as? String ?? Utils.n_a
    }
}
