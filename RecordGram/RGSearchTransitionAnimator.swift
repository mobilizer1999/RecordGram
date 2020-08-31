//
//  RGSearchTransitionAnimator.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/15/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit

private let RGCustomTransitionDuration: TimeInterval = 0.4
private let RGUpdateViewConstraintsDelay: TimeInterval = 0.1
private let RGSearchBarHeight: CGFloat = 100

let screenSize = UIScreen.main.bounds
let screenWidth = screenSize.width
let screenHeight = screenSize.height


protocol RGSearchBarViewsProvider: NSObjectProtocol {
    func searchBarView() -> UIView
    func mainView() -> UIView
}

class RGSearchTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    
        var isPresenting: Bool = false
    
        // MARK: - INIT
    
        init(isPresenting: Bool) {
            super.init()
    
            self.isPresenting = isPresenting
        }
    
        // MARK: - UIViewControllerAnimatedTransitioning Methods
        // This is used for percent driven interactive transitions, as well as for
        // container controllers that have companion animations that might need to
        // synchronize with the main animation.
        func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
            return RGCustomTransitionDuration
        }
    
        // This method can only  be a nop if the transition is interactive and not a percentDriven interactive transition.
        // -(void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext
        func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
            let toViewController: UIViewController? = transitionContext.viewController(forKey: .to)
            let fromViewController: UIViewController? = transitionContext.viewController(forKey: .from)
            let toView: UIView? = toViewController?.view
            let fromView: UIView? = fromViewController?.view
            var searchBarView: UIView?
            var mainView: UIView?
    
            if isPresenting {
                transitionContext.containerView.addSubview(toView!)
                var targetViewController: UIViewController? = toViewController
                // When presenting, toView => Search Screen,  fromView => Presenting View
                if (toViewController is UINavigationController) {
                    targetViewController = (toViewController as? UINavigationController)?.childViewControllers[0]
                }
                if targetViewController is RGSearchBarViewsProvider {
                    weak var provider: RGSearchBarViewsProvider? = (targetViewController as? RGSearchBarViewsProvider)
                    searchBarView = provider?.searchBarView()
                    mainView = provider?.mainView()
                }
            }
            else {
                transitionContext.containerView.addSubview(fromView!)
                var targetViewController: UIViewController? = fromViewController
                // When dismissing, toView => Presenting View,  fromView => Search Screen
                if (fromViewController is UINavigationController) {
                    targetViewController = (fromViewController as? UINavigationController)?.childViewControllers[0]
                }
                if targetViewController is RGSearchBarViewsProvider {
                    weak var provider: RGSearchBarViewsProvider? = (targetViewController as? RGSearchBarViewsProvider)
                    searchBarView = provider?.searchBarView()
                    mainView = provider?.mainView()
                }
            }
    
            if nil != searchBarView && nil != mainView {
                let duration: TimeInterval = transitionDuration(using: transitionContext)
                let searchBarHeight: CGFloat = searchBarView!.frame.height
                searchBarView?.autoresizingMask = []
                if isPresenting {
                    searchBarView?.frame = CGRect(x: 0, y: -searchBarHeight, width: screenWidth, height: searchBarHeight)
                    mainView?.alpha = 0.0
                }
                UIView.animate(withDuration: duration, animations: {() -> Void in
                    if self.isPresenting {
                        searchBarView?.frame = CGRect(x: 0, y: 0, width: screenWidth, height: searchBarHeight)
                        mainView?.alpha = 1.0
                    }
                    else {
                        searchBarView?.frame = CGRect(x: 0, y: -searchBarHeight, width: screenWidth, height: searchBarHeight)
                        mainView?.alpha = 0.0
                    }
                }, completion: {(_ finished: Bool) -> Void in
                    transitionContext.completeTransition(true)
                })
            }
            else {
    //            NSException.raise(NSExceptionName(rawValue: "\(toViewController) must adopt RGSearchBarViewsProvider protocol to use RGSearchTransitionAnimator."))
            }
    
        }
        
    
 
}


    
    
    
    

    
    
    
    
    
    
    
    
    
    
    
    
    
    
