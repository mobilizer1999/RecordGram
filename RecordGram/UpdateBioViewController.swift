//
//  UpdateBioViewController.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 10/31/17.
//

import UIKit

protocol UpdateBioProtocol {
    func userUpdated(string: String)
}

class UpdateBioViewController: UIViewController, ErrorHandler {

    let userDefualts = UserDefaults.standard
    var delegate: UpdateBioProtocol!

    @IBOutlet weak var bioTextView: UITextView!
    @IBOutlet var toolbar: UIToolbar!

    override func viewDidLoad() {
        super.viewDidLoad()
        bioTextView.becomeFirstResponder()
        bioTextView.inputAccessoryView = toolbar
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UserClient.shared.get("bio") { bio in
            self.bioTextView.text = bio.decodeEmoji
        }
    }

    @IBAction func onCloseButton(_ sender: UIButton) {
        bioTextView.resignFirstResponder()
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func onSaveButton(_ sender: UIBarButtonItem) {
        UserClient.shared.update(bio: bioTextView.text!, success: { _ in
            self.bioTextView.resignFirstResponder()
            self.dismiss(animated: true, completion: nil)
        }, failure: { error in
            self.presentErrorDialog(error: error)
        })
    }
}
