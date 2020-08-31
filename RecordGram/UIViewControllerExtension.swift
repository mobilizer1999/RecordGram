//
//  UIViewControllerExtension.swift
//  RecordGram
//
//  Created by Mauro Taroco on 11/9/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import Foundation
import UIKit
import AccountKit
import Kingfisher

// MARK: - Alerts {
extension UIViewController {

    // https://stackoverflow.com/a/42622755/5124849
    // Just make sure actionTitles and actions array the same count. Pass nil if you don't need any action handler closure.
    // Invoke like:
    /*
     self.showAlert(title: "Title", message: " Oops, xxxx ", actionTitles: ["Option1","Option2","Option3"], actions:[{action1 in
     
     },{action2 in
     
     }, nil])
     */
    func showAlert(title: String?, message: String?, actionTitles: [String?], actions: [((UIAlertAction) -> Void)?], preferredStyle: UIAlertControllerStyle = .alert) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: preferredStyle)
        for (index, title) in actionTitles.enumerated() {
            let action = UIAlertAction(title: title, style: .default, handler: actions[index])
            alert.addAction(action)
        }
        self.present(alert, animated: true, completion: nil)
    }

    func signOut() {
        DeviceClient.shared.detach()
        AKFAccountKit(responseType: .accessToken).logOut()
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        UserDefaults.standard.synchronize()
        UserClient.shared.user = nil
        self.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
    }

    func noTabs() {
        tabBarController?.tabBar.isHidden = true
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    func load(_ profileNavButton: UIButton) {
        // Clear out old subviews
        for view in profileNavButton.subviews {
            view.removeFromSuperview()
        }

        let imageView = UIImageView(frame: CGRect.init(x: 0, y: 0, width: 25, height: 25))
        imageView.contentMode = .scaleAspectFill

        if let profilePicture = UserClient.shared.profilePicture {
            imageView.image = profilePicture
            profileNavButton.addSubview(imageView)
        } else {
            UserClient.shared.get("profile_picture") { profilePicture in
                imageView.kf.setImage(with: URL(string: profilePicture), placeholder: UIImage(named: "profile_placeholder"))
                profileNavButton.addSubview(imageView)
            }
        }
    }

    func setupNavigationBarBackButton() {
        self.navigationController?.navigationBar.topItem?.title = ""
        let backButtonImage = UIImage(named: "backArrow")
        self.navigationController?.navigationBar.backIndicatorImage = backButtonImage
        self.navigationController?.navigationBar.backIndicatorTransitionMaskImage = backButtonImage
    }

    @IBAction func onSearchButton(_ sender: Any) {
        let storyboard = UIStoryboard.init(name: "Helpers", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "SearchResultsViewController") as! SearchResultsViewController
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.modalPresentationStyle = .custom
        navigationController.modalTransitionStyle = .crossDissolve
        self.present(navigationController, animated: true, completion: nil)
    }

    @IBAction func onProfileButton(_ sender: Any) {
        goToMyProfile()
    }

    func goToMyProfile() {
        if let user = UserClient.shared.user {
            goToProfile(uuid: UserClient.shared.uuid(), arUser: user["is_anr"].boolValue)
        } else {
            goToProfile(uuid: UserClient.shared.uuid())
        }
    }

    func goToProfile(uuid: String, arUser: Bool = false) {
        if arUser {
            let storyBoard: UIStoryboard = UIStoryboard(name: "ARUser", bundle: nil)
            let profileVC = storyBoard.instantiateViewController(withIdentifier: "ARProfileViewController") as! ARProfileViewController
            profileVC.uuid = uuid
            self.navigationController?.pushViewController(profileVC, animated: true)
        } else {
            let profileVC = UIStoryboard(name: "Profile", bundle: nil).instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
            profileVC.uuid = uuid
            if let navigationController = self.navigationController {
                navigationController.pushViewController(profileVC, animated: true)
            }
        }
    }

    func goToProducerProfile(with uuid: String) {
        let producerVC = UIStoryboard(name: "Music", bundle: nil).instantiateViewController(withIdentifier: "ProducerBeatsViewController") as! ProducerBeatsViewController
        producerVC.uuid = uuid
        if let navigationController = self.navigationController {
            navigationController.pushViewController(producerVC, animated: true)
        }
    }

    func goToStudioAndPresentMyStudio() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.mainTab?.goToStudioAndShowMyStudio()
    }

    func setFollowUnFollowButton(_ button: UIButton, amFollowing: Bool) {
        if amFollowing {
            let color = UIColor(hex: "B3225B")
            button.setImage(UIImage(named: "unfollow"), for: .normal)
            button.layer.borderColor = color.cgColor
            button.tintColor = color
        } else {
            let color = UIColor(hex: "37ADEB")
            button.setImage(UIImage(named: "follow"), for: .normal)
            button.layer.borderColor = color.cgColor
            button.tintColor = color
        }
    }

    func openCoinsPopover() {
        let storyBoard = UIStoryboard(name: "CoinsPopover", bundle: nil)
        let coinsVC = storyBoard.instantiateViewController(withIdentifier: "CoinsPopoverViewController") as! CoinsPopoverViewController
        coinsVC.modalPresentationStyle = .overCurrentContext
        present(coinsVC, animated: true, completion: nil)
    }

    func otherUserSettings(with uuid: String) {
        UserClient.shared.get("am_blocking", for: uuid) { amBlockingString in
            let amBlocking = amBlockingString == "1"
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let text = amBlocking ? NSLocalizedString("Unblock User", comment: "User action") : NSLocalizedString("Block User", comment: "User action")
            alertController.addAction(UIAlertAction(title: text, style: .destructive) { alert in
                if amBlocking {
                    UserClient.shared.unblock(uuid, success: {
                        UserClient.shared.invalidateUser(with: uuid)
                    }, failure: { error in
                        print("Error Unblocking", error)
                    })
                } else {
                    UserClient.shared.block(uuid, success: {
                        UserClient.shared.invalidateUser(with: uuid)
                    }, failure: { error in
                        print("Error Blocking", error)
                    })
                }
            })
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Dialog"), style: .cancel, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
    }
}


//Keyboard actions
extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        gesture.cancelsTouchesInView = false

        view.addGestureRecognizer(gesture)
    }

    @objc func dismissKeyboard(_ gesture: UIGestureRecognizer) {
        guard gesture.state == .ended else {
            return
        }

        view.endEditing(true)
    }
}
