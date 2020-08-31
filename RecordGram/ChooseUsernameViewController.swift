//
//  ChooseUsernameViewController.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 10/10/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.

import UIKit

class ChooseUsernameViewController: UIViewController, ErrorHandler {

    @IBOutlet weak var usernameTextField: UITextField!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.statusBarStyle = .default
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.statusBarStyle = .lightContent
        usernameTextField.resignFirstResponder()
    }

    @IBAction func onSetUsernameButton(_ sender: Any) {
        guard let textFieldText = usernameTextField.text else {
            return
        }
        if textFieldText.isEmpty {
            presentErrorDialog(string: NSLocalizedString("Please choose a valid username before continuing.", comment: "Form validation"))
        } else {
            UserClient.shared.update(username: textFieldText, success: { response in
                UserDefaults.standard.set(textFieldText, forKey: kUserNameKey)
                let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
                let viewController = storyboard.instantiateViewController(withIdentifier: "MainTabBarController") as! MainTabBarController
                viewController.shouldShowTour = true
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                appDelegate.mainTab = viewController
                self.present(viewController, animated: true)
            }, failure: { error in
                self.presentErrorDialog(error: error)
            })
        }
    }
}

