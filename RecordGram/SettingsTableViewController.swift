//
//  ProfileSettingsTableViewController.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/7/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import AccountKit

class SettingsTableViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    fileprivate var accountKit = AKFAccountKit(responseType: .accessToken)
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!


    @IBOutlet weak var profileImageView: RoundImageView!

    var userDefaults = UserDefaults.standard

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if
                let navigationController = segue.destination as? UINavigationController,
                let viewController = navigationController.topViewController as? UpdateStageNameViewController,
                let tableViewCell = sender as? UITableViewCell,
                let indexPath = tableView.indexPath(for: tableViewCell) {
            switch indexPath.section {
            case 1:
                switch indexPath.row {
                case 0:
                    viewController.selectedParameter = .username
                case 1:
                    viewController.selectedParameter = .phone_number
                case 2:
                    viewController.selectedParameter = .email
                default:
                    break

                }
            default:
                break

            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tabBarController?.tabBar.isTranslucent = true

        noTabs()

        UserClient.shared.get("username") { username in
            self.usernameLabel.text = username
        }
        UserClient.shared.get("email") { email in
            self.emailLabel.text = email
        }
        UserClient.shared.get("phone_number") { phone in
            self.phoneLabel.text = phone
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                print("selected facebook cell")
            case 1:
                print("selected twitter cell")
            default:
                break
            }
        case 1:
            switch indexPath.row {
            case 0:
                print("stage name selected")
            case 1:
                print("Phone cell selected")
            case 2:
                print("email cell selected")
            case 3:
                print("Password cell selected")
            default:
                break
            }
        case 2:
            switch indexPath.row {
            case 0:
                presentDeactivateProfileAlert()
            case 1:
                // print("Blocked users cell")
                break
            default:
                break
            }
        default:
            break
        }
    }

    fileprivate func presentDeactivateProfileAlert() {
        let alertController = UIAlertController(title: NSLocalizedString("Alert!", comment: "Dialog title"), message: NSLocalizedString("Are you sure you want to deactivate your profile?", comment: "Dialog message"), preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("YES", comment: "Dialog option"), style: .destructive) { (action) in
            self.signOut()
        })
        alertController.addAction(UIAlertAction(title: NSLocalizedString("NO", comment: "Dialog option"), style: .cancel))
        self.present(alertController, animated: true, completion: nil)
    }

    // PICK NEW PROFILE IMAGE

    @IBAction func onAddPhotoButton(_ sender: UIButton) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        present(imagePickerController, animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            profileImageView.image = editedImage.withRenderingMode(.alwaysOriginal)
            UserClient.shared.profilePicture = editedImage
            UserClient.shared.update(profilePicture: editedImage, success: { _ in }, failure: { _ in })
        }
//        else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
//            profileImageView.image = originalImage.withRenderingMode(.alwaysOriginal)
//        }
//        profileImageView.layer.masksToBounds = true
        dismiss(animated: true, completion: nil)
    }
}
