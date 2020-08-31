//
//  FindYourFriendsViewController.swift
//  RecordGram
//
//  Created by Nicolas Gonzalez on 3/21/18.
//  Copyright © 2018 Meridian Inc. All rights reserved.
//

import UIKit
import Contacts

class FindYourFriendsViewController: UIViewController {

    var mainTabBarController: MainTabBarController!

    @IBAction func didTapContinue() {
        CNContactStore().requestAccess(for: .contacts) { granted, error in
            self.dismiss(animated: true) {
                guard granted, let navigationController = self.mainTabBarController.selectedViewController as? UINavigationController else {
                    return
                }

                let storyBoard = UIStoryboard(name: "Menu", bundle: nil)
                let findFollowVC = storyBoard.instantiateViewController(withIdentifier: "FindFollowTableViewController") as! FindFollowTableViewController

                findFollowVC.findAndFollowContactPhone()

                navigationController.pushViewController(findFollowVC, animated: true)
            }
        }
    }

    @IBAction func didTapSkip() {
        dismiss(animated: true) {
            LocationTracker.shared.getCurrentLocation(completionHandler: nil)
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.mainTab?.shouldShowTour = false
        }
    }
}
