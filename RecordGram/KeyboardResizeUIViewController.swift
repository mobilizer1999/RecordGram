//
// Created by Nicolas Gonzalez on 11/29/17.
// Copyright (c) 2017 Meridian Inc. All rights reserved.
//

import UIKit

class KeyboardResizeUIViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(
                self,
                selector: #selector(KeyboardResizeUIViewController.keyboardWillChangeForResizing),
                name: Notification.Name.UIKeyboardWillShow,
                object: nil
        )
        NotificationCenter.default.addObserver(
                self,
                selector: #selector(KeyboardResizeUIViewController.keyboardWillChangeForResizing),
                name: Notification.Name.UIKeyboardWillHide,
                object: nil
        )
    }

    @objc func keyboardWillChangeForResizing(_ notification: Notification) {
        if let userInfo = notification.userInfo,
           let keyboardSize = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            UIView.beginAnimations("AnimateView", context: nil)
            UIView.setAnimationCurve(UIViewAnimationCurve(rawValue: userInfo[UIKeyboardAnimationCurveUserInfoKey] as! Int)!)
            UIView.setAnimationDuration(userInfo[UIKeyboardAnimationDurationUserInfoKey] as! Double)
            self.view.frame = CGRect(
                    x: self.view.frame.origin.x,
                    y: self.view.frame.origin.y,
                    width: self.view.frame.width,
                    height: notification.name == NSNotification.Name.UIKeyboardWillShow ?
                    keyboardSize.origin.y - self.view.frame.origin.y : self.view.frame.height + keyboardSize.height
            )
            self.view.layoutIfNeeded()
            UIView.commitAnimations()
        }
    }
}