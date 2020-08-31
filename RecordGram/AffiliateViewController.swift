//
//  AffiliateViewController.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 10/11/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.

import UIKit

class AffiliateViewController: UIViewController, UIGestureRecognizerDelegate {
    var homeVC: HomeViewController!
    @IBOutlet weak var contentView: RoundButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBlurView()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(AffiliateViewController.dismissViewController))
        tapGesture.numberOfTapsRequired = 1
        tapGesture.delegate = self
        self.view.addGestureRecognizer(tapGesture)
    }
    
    @objc func dismissViewController() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onCancelButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if (touch.view?.isDescendant(of: contentView))!{
            return false
        }
        return true
    }
    
    func setupBlurView() {
        let blur = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: blur)
        blurView.frame = contentView.bounds
        contentView.addSubview(blurView)
        contentView.sendSubview(toBack: blurView)
        blurView.alpha = 0.8
    }

}
