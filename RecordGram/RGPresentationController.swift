//
//  RGPresentationController.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/16/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit

final class RGPresentationController: UIPresentationController {
    var touchForwardingView: PSPDFTouchForwardingView!
    
    override var frameOfPresentedViewInContainerView: CGRect {
        let height : CGFloat = 100
        return CGRect(x: 0, y: 100 - height, width: (containerView?.bounds.width)!, height: height)
    }
    
    override func containerViewWillLayoutSubviews() {
        presentedView?.frame = frameOfPresentedViewInContainerView
    }
        
    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        touchForwardingView = PSPDFTouchForwardingView(frame: (containerView?.bounds)!)
        touchForwardingView.passthroughViews = [presentingViewController.view]
        containerView?.insertSubview(touchForwardingView, at: 0)
    }

}
