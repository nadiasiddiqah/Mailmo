//
//  PulseAnimation.swift
//  Mailmo
//
//  Created by Nadia Siddiqah on 6/8/21.
//

import Foundation
import UIKit

class PulseAnimation: CALayer {
    
    var animationGroup = CAAnimationGroup()
    var animationDuration: TimeInterval = 2
    var radius: CGFloat = 25
    var numberOfPulses: Float = Float.infinity
    
    // Default initializer
    override init(layer: Any) {
         super.init(layer: layer)
    }
         
    // Required initializer
    required init?(coder aDecoder: NSCoder) {
         fatalError("init(coder:) has not been implemented")
    }
    
    // Custom initializer with parameters
    init(numberOfPulses: Float = Float.infinity, radius: CGFloat, position: CGPoint) {
        super.init()
        self.backgroundColor = UIColor.black.cgColor
        self.contentsScale = UIScreen.main.scale
        self.opacity = 0
        self.radius = radius
        self.numberOfPulses = numberOfPulses
        self.position = position
         
        self.bounds = CGRect(x: 0, y: 0, width: radius*2, height: radius*2)
        self.cornerRadius = 20
         
        DispatchQueue.global(qos: .default).async {
           self.setupAnimationGroup()
           DispatchQueue.main.async {
                self.add(self.animationGroup, forKey: "pulse")
          }
       }
    }
    
    // Expand pulse from 0 -> n radius
    func scaleAnimation() -> CABasicAnimation {
         let scaleAnimation = CABasicAnimation(keyPath: "transform.scale.xy")
         scaleAnimation.fromValue = NSNumber(value: 0.25)
         scaleAnimation.toValue = NSNumber(value: 1.0)
         scaleAnimation.duration = animationDuration
         return scaleAnimation
    }
    
    // Change opacity when pulse size increases
    func opacityAnimation() -> CAKeyframeAnimation {
         let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
         opacityAnimation.duration = animationDuration
         opacityAnimation.values = [0.4, 0.8, 0]
         opacityAnimation.keyTimes = [0, 0.3, 1]
         return opacityAnimation
    }
    
    // Group animations
    func setupAnimationGroup() {
          self.animationGroup.duration = animationDuration
          self.animationGroup.repeatCount = numberOfPulses
          let defaultCurve = CAMediaTimingFunction(name: CAMediaTimingFunctionName.default)
          self.animationGroup.timingFunction = defaultCurve
          self.animationGroup.animations = [scaleAnimation(), opacityAnimation()]
    }
}
