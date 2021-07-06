//
//  AppStoreReviewManager.swift
//  Mailmo
//
//  Created by Nadia Siddiqah on 6/2/21.
//

import Foundation
import StoreKit

struct AppStoreReviewManager {
    
    static func requestReviewIfAppropriate(scene: UIWindowScene) {
        SKStoreReviewController.requestReview(in: scene)
    }
}
