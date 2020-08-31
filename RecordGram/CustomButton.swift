//
//  CustomButton.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/5/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit

@IBDesignable public class RoundButton: UIButton {
    
    @IBInspectable var borderColor: UIColor = UIColor.white {
        didSet {
            layer.borderColor = borderColor.cgColor
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 2.0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    
    @IBInspectable
    public var cornerRadius: CGFloat = 2.0 {
        didSet {
            self.layer.cornerRadius = self.cornerRadius
        }
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        clipsToBounds = true
    }
}

extension UIButton {
    func applyBlurEffect() {
        let blur = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: blur)
        blurView.frame = self.bounds
        blurView.layer.cornerRadius = 20
        blurView.clipsToBounds = true
        blurView.isUserInteractionEnabled = false
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.insertSubview(blurView, at: 1)
    }
}

