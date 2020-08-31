//
//  UIViewExtension.swift
//  RecordGram
//
//  Created by Mauro Taroco on 12/27/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    
    // MARK: - Animations & Effects
    func rgThemeAnimate() {
        transform = CGAffineTransform(scaleX: 0.65, y: 0.65)
        UIView.animate(withDuration: 0.65, delay: 0.0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.0, options: .allowUserInteraction, animations: {() -> Void in
            self.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        }, completion: {(_ finished: Bool) -> Void in
        })
    }
    
    func rgThemeShake() {
        shake(withDuration: 0.05, repeatCount: 2)
    }
    
    func shake(withDuration duration: CGFloat, repeatCount `repeat`: Int) {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = duration as? CFTimeInterval ?? CFTimeInterval()
        animation.repeatCount = Float(`repeat`)
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: center.x - 5.0, y: center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: center.x + 5.0, y: center.y))
        layer.add(animation, forKey: "position")
    }
    
    func showRippleEffect(onLocation point: CGPoint, circleRadius radius: CGFloat, andWave color: UIColor) {
        // Replace the view tapped with one that will expand
        let targetFrame = CGRect(x: point.x - radius, y: point.y - radius, width: 2 * radius, height: 2 * radius)
        let wave = UIView(frame: targetFrame)
        wave.backgroundColor = color
        wave.alpha = 0.5
        wave.layer.masksToBounds = true
        wave.layer.cornerRadius = wave.frame.size.width / 2
        // Hide it below the original view
        insertSubview(wave, belowSubview: self)
        // Create a view that is the same colour as self.view to make it look like a hole
        let center = UIView(frame: targetFrame)
        center.backgroundColor = UIColor.clear
        center.layer.masksToBounds = true
        center.layer.cornerRadius = center.frame.size.width / 2
        insertSubview(center, aboveSubview: wave)
        // Hide the original view
        alpha = 1.0
        // IMPORTANT: I send these views behind the others so that center does not overlap them
        sendSubview(toBack: center)
        sendSubview(toBack: wave)
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveLinear, animations: {() -> Void in
            let waveTransform: CGAffineTransform = wave.transform
            let centerTransform: CGAffineTransform = center.transform
            // Expand the views to look like a shockwave
            wave.transform = waveTransform.scaledBy(x: 4, y: 4)
            center.transform = centerTransform.scaledBy(x: 5.75, y: 5.75)
            // Fade the wave out to nothing
            wave.alpha = 0
        }, completion: {(_ finished: Bool) -> Void in
            // Remove the shockwave
            wave.removeFromSuperview()
            center.removeFromSuperview()
        })
    }
    
}

extension UIView {
    
    func insetsZeroToSuperview() {
        self.snp.makeConstraints { (make) -> Void in
            make.edges.equalTo(self.superview!).inset(UIEdgeInsets.zero)
        }
    }
    
    func constraintsEqualToView(view: UIView) {
        self.snp.makeConstraints { (make) -> Void in
            make.edges.equalTo(view).inset(UIEdgeInsets.zero)
        }
    }
}

extension UIView {
    
    @discardableResult
    func loadViewFromNib<T: UIView>() -> T? {
        guard let contentView = Bundle.main.loadNibNamed(self.className, owner: self, options: nil)?.first as? T else {
            // xib not loaded, or it's top view is of the wrong type
            return nil
        }
        self.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.insetsZeroToSuperview()
        return contentView
    }
}

extension UIView {
    
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}
