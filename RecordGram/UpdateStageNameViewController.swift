//
//  UpdateStageNameViewController.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/8/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit

class UpdateStageNameViewController: UIViewController, ErrorHandler {
    @IBOutlet weak var txtStageName: UITextField!

    var selectedParameter: Parameter!

    enum Parameter: String {
        case username
        case phone_number
        case email
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        switch selectedParameter {
        case .username?:
            title = NSLocalizedString("UPDATE STAGE NAME", comment: "Stage name")
            txtStageName.placeholder = NSLocalizedString("Stage Name", comment: "Stage name")
        case .phone_number?:
            title = NSLocalizedString("UPDATE PHONE", comment: "Stage name")
            txtStageName.placeholder = NSLocalizedString("Phone", comment: "Stage name")
        case .email?:
            title = NSLocalizedString("UPDATE EMAIL", comment: "Stage name")
            txtStageName.placeholder = NSLocalizedString("Email", comment: "Stage name")
        default:
            break
        }

        UserClient.shared.get(selectedParameter.rawValue) { parameter in
            self.txtStageName.text = parameter
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        noTabs()
    }

    @IBAction func didTapCancelButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func didTapSaveButton(_ sender: Any) {
        UserClient.shared.update(parameters: [selectedParameter.rawValue: self.txtStageName.text!], success: { _ in
            self.dismiss(animated: true, completion: nil)
        }, failure: { error in
            self.presentErrorDialog(error: error)
        })
    }
}
