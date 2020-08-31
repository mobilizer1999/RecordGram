//
//  FollowingTableViewController.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/8/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import PagedArray

class FollowingTableViewController: UITableViewController {

    let following = FollowingComponent()

    let placeholder = UIImage(named: "profile_placeholder")

    var uuid: String!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("Following", comment: "Following")
        self.navigationController?.navigationBar.topItem?.title = ""
        let backButtonImage = UIImage(named: "backArrow")
        self.navigationController?.navigationBar.backIndicatorImage = backButtonImage
        self.navigationController?.navigationBar.backIndicatorTransitionMaskImage = backButtonImage

        loadData()
    }

    func loadData() {
        following.load(uuid: uuid, view: tableView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isTranslucent = false
        tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
        tabBarController?.tabBar.isHidden = true
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return following.array.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "followingCell", for: indexPath) as! FollowingTableViewCell

        if let following = following.array[indexPath.item] {
            if let username = following.username {
                cell.userInfoLabel.text = "@\(username)"
            } else {
                cell.userInfoLabel.text = ""
            }
            if let picture = following.picture {
                cell.userImageView.kf.setImage(with: picture, placeholder: placeholder)
            } else {
                cell.userImageView.image = placeholder
            }
            if let uuid = following.uuid {
                cell.uuid = uuid
                if uuid == UserClient.shared.uuid() {
                    cell.followButton.isHidden = true
                } else {
                    cell.followButton.isHidden = false
                    if let amFollowing = following.amFollowing {
                        cell.amFollowing = amFollowing
                        setFollowUnFollowButton(cell.followButton, amFollowing: amFollowing)
                    }
                }
            } else {
                cell.uuid = ""
            }
            if let isVerified = following.isVerified, isVerified {
                cell.verifyImageView.isHidden = false
            } else {
                cell.verifyImageView.isHidden = true
            }
        } else {
            cell.userInfoLabel.text = ""
            cell.userImageView.image = placeholder
            cell.uuid = ""
            cell.followButton.isHidden = true
            cell.verifyImageView.isHidden = true
            following.loadIfNeeded(uuid: uuid, for: indexPath, view: tableView)
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let user = following.array[indexPath.row], let uuid = user.uuid, let arUser = user.isANR {
            goToProfile(uuid: uuid, arUser: arUser)
        }
    }
}
