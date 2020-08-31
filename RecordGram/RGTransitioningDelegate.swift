//
//  RGTransitioningDelegate.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/16/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit

class RGTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {

    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return RGPresentationController(presentedViewController: presented, presenting: presenting)
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return RGPresentationAnimator()
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return RGDismissionAnimator()
    }
}
