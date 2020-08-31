//
//  MenuViewController.swift
//  RecordGram
//  Created by Roman Salazar Lopez on 9/5/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit

class MenuViewController: UIViewController {
  
    @IBOutlet weak var viewBlack: UIView!
    @IBOutlet weak var viewMenu: UIView!
    @IBOutlet weak var constraintMenuLeft: NSLayoutConstraint!
    @IBOutlet weak var constraintMenuWidth: NSLayoutConstraint!
    
    var homeVC: HomeViewController!
    var musicVC: MusicViewController!
    var creationsVC: CreationsViewController!
    var stageVC: StageViewController!
    var studioVC: StudioViewController!
    
    let maxBlackViewAlpha: CGFloat = 0.5
    let animationDuration: TimeInterval = 0.38
    var isLeftToRight = true

    var menuContentVC: MenuContentViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGesture = UITapGestureRecognizer()
        tapGesture.cancelsTouchesInView = false
        tapGesture.addTarget(self, action: #selector(MenuViewController.gestureTap(_:)))
        viewBlack.addGestureRecognizer(tapGesture)

        constraintMenuLeft.constant = -constraintMenuWidth.constant
        
        viewBlack.alpha = 0
        viewBlack.isHidden = true
        
//        let language = NSLocale.preferredLanguages.first!
//        let direction = NSLocale.characterDirection(forLanguage: language)
    }


    @IBAction func gesturePan(_ sender: UIPanGestureRecognizer) {
        
        // retrieve the current state of the gesture
        if sender.state == UIGestureRecognizerState.began {
            
            // no need to do anything
        } else if sender.state == UIGestureRecognizerState.changed {
            
            // retrieve the amount viewMenu has been dragged
            var translationX = sender.translation(in: sender.view).x
            
            if !isLeftToRight {
                translationX = -translationX
            }
            
            if translationX > 0 {
                
                // viewMenu fully dragged out
                constraintMenuLeft.constant = 0
                viewBlack.alpha = maxBlackViewAlpha
                
            } else if translationX < -constraintMenuWidth.constant {
                
                // viewMenu fully dragged in
                constraintMenuLeft.constant = -constraintMenuWidth.constant
                viewBlack.alpha = 0
                
            } else {
                
                // it's being dragged somewhere between min and max amount
                constraintMenuLeft.constant = translationX
                
                let ratio = (constraintMenuWidth.constant + translationX) / constraintMenuWidth.constant
                let alphaValue = ratio * maxBlackViewAlpha
                viewBlack.alpha = alphaValue
            }
        } else {
            
            // if the drag was less than half of it's width, close it. Otherwise, open it.
            if constraintMenuLeft.constant < -constraintMenuWidth.constant / 2 {
                self.hideMenu()
            } else {
                self.openMenu()
            }
        }
    }
 
    @IBAction func gestureTap(_ sender: UITapGestureRecognizer) {
        self.hideMenu()
    }
    
    func openMenu() {

        menuContentVC?.profilImage.fetch()

        // when menu is opened, it's left constraint should be 0
        constraintMenuLeft.constant = 0
        
        // view for dimming effect should also be shown
        viewBlack.isHidden = false
        
        // animate opening of the menu - including opacity value
        UIView.animate(withDuration: animationDuration, animations: {
            
            self.view.layoutIfNeeded()
            self.viewBlack.alpha = self.maxBlackViewAlpha
            
        }, completion: { (complete) in

        })
    }
    
    func hideMenu() {
        //when userInteracton is enabled, touches on home screen dont register. so turn off
        if homeVC != nil {
            homeVC.menuView.isUserInteractionEnabled = false
        }
        if musicVC != nil {
            musicVC.menuView.isUserInteractionEnabled = false
        }
        if studioVC != nil {
            studioVC.menuView.isUserInteractionEnabled = false
        }
        if creationsVC != nil {
            creationsVC.menuView.isUserInteractionEnabled = false
        }
        if stageVC != nil {
            stageVC.menuView.isUserInteractionEnabled = false
        }

        // when menu is closed, it's left constraint should be of value that allows it to be completely hidden to the left of the screen - which is negative value of it's width
        constraintMenuLeft.constant = -constraintMenuWidth.constant
        
        // animate closing of the menu - including opacity value
        UIView.animate(withDuration: animationDuration, animations: {
            
            self.view.layoutIfNeeded()
            self.viewBlack.alpha = 0
            
        }, completion: { (complete) in
            
            // hide the view for dimming effect so it wont interrupt touches for views underneath it
            self.viewBlack.isHidden = true
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? MenuContentViewController {
            vc.homeVC = homeVC
            vc.musicVC = musicVC
            vc.studioVC = studioVC
            vc.creationsVC = creationsVC
            vc.stageVC = stageVC
            vc.parentVC = self
            menuContentVC = vc
        }
    }
}
