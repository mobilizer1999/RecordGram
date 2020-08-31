//
//  SetPasswordViewController.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/8/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit

class SetPasswordViewController: UIViewController, ErrorHandler {
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var txtPasswordConfirmation: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        noTabs()
    }

    @IBAction func didTapCancelButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func didTapSaveButton(_ sender: Any) {
        if txtPassword.text == txtPasswordConfirmation.text {
            UserClient.shared.update(password: txtPassword.text!, success: { _ in
                self.dismiss(animated: true, completion: nil)
            }, failure: { error in
                self.presentErrorDialog(error: error)
            })
        } else {
            let viewController = UIAlertController(title: NSLocalizedString("Ops!", comment: "Dialog title"), message: NSLocalizedString("Passwords do not match.", comment: "Dialog message"), preferredStyle: .alert)
            viewController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Dialog option"), style: .default, handler: nil))
            present(viewController, animated: true, completion: nil)
        }
    }
}
