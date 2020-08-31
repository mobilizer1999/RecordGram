//
//  FansTableViewController.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/8/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import PagedArray

class FansTableViewController: UITableViewController, UITableViewDataSourcePrefetching {
    var uuid: String!
    
    private lazy var fansMediaComponent = FansMediaComponent(uuid: self.uuid)
    
    private lazy var placeholder = UIImage(named: "profile_placeholder")
    private lazy var followUser = UIImage(named: "follow")
    private lazy var unFollowUser = UIImage(named: "unfollow")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("Fans", comment: "Fans")
        self.navigationController?.navigationBar.topItem?.title = ""
        
        let backButtonImage = UIImage(named: "backArrow")
        self.navigationController?.navigationBar.backIndicatorImage = backButtonImage
        self.navigationController?.navigationBar.backIndicatorTransitionMaskImage = backButtonImage
        
        tableView.prefetchDataSource = self
        
        fansMediaComponent.load(tableView: tableView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.isTranslucent = false
        tabBarController?.tabBar.isHidden = true
        tabBarController?.tabBar.isTranslucent = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tabBarController?.tabBar.isHidden = true
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fansMediaComponent.count()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "fansCell", for: indexPath) as! FansTableViewCell
        
        if let user = fansMediaComponent.item(at: indexPath) {
            if let username = user.username {
                cell.userInfoLabel.text = "@\(username)"
            } else {
                cell.userInfoLabel.text = ""
            }
            if let picture = user.picture {
                cell.userImageView.kf.setImage(with: picture, placeholder: placeholder)
            } else {
                cell.userImageView.image = placeholder
            }
            if let uuid = user.uuid {
                cell.uuid = uuid
                if uuid == UserClient.shared.uuid() {
                    cell.followButton.isHidden = true
                } else {
                    cell.followButton.isHidden = false
                    if let amFollowing = user.amFollowing {
                        cell.amFollowing = amFollowing
                        setFollowUnFollowButton(cell.followButton, amFollowing: amFollowing)
                    }
                }
            } else {
                cell.uuid = ""
            }
            if let isVerified = user.isVerified, isVerified {
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
        }
        
        fansMediaComponent.loadDataIfNeeded(for: indexPath, on: tableView)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let user = fansMediaComponent.item(at: indexPath), let uuid = user.uuid, let arUser = user.isANR else {
            return
        }
        
        goToProfile(uuid: uuid, arUser: arUser)
    }
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach({ fansMediaComponent.loadDataIfNeeded(for: $0, on: tableView) })
    }
}
