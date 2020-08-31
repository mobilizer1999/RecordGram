//
//  ModalViewController.swift
//  RecordGram
//
//  Created by Nicolas Gonzalez on 4/12/18.
//  Copyright © 2018 Meridian Inc. All rights reserved.
//

import UIKit

class ModalViewController: UIViewController {

    @IBOutlet weak var visualEffectView: UIVisualEffectView!

    var backgroundView = UIView(frame: UIScreen.main.bounds)

    override func loadView() {
        backgroundView.backgroundColor = .clear
        UIApplication.shared.keyWindow?.addSubview(backgroundView)
        super.loadView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapView))
        gesture.cancelsTouchesInView = true
        view.addGestureRecognizer(gesture)

        UIView.animate(withDuration: 0.2) {
            self.backgroundView.backgroundColor = UIColor(white: 0, alpha: 0.3)
        }
    }

    @objc func didTapView(_ gesture: UIGestureRecognizer) {
        let touchLocation = gesture.location(in: self.view)

        if !visualEffectView.frame.contains(touchLocation) {
            close()
        }
    }

    func close(_ completion: (() -> Void)? = nil) {
        self.dismiss(animated: true) {
            completion?()
        }
        UIView.animate(withDuration: 0.2, animations: {
            self.backgroundView.backgroundColor = .clear
        }) { _ in
            self.backgroundView.removeFromSuperview()
        }
    }
}
