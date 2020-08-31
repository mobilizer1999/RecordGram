//
//  ArtistCollectionViewCell.swift
//  RecordGram
//
//  Created by Nicolas Gonzalez on 1/17/18.
//  Copyright © 2018 Meridian Inc. All rights reserved.
//

import UIKit

class ArtistCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var profile: RoundImageView!
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var button: UIButton!
    
    var uuid = ""
    var amFollowing: Bool!

    @IBAction func onButton(_ sender: Any) {
        if let parentViewController = parentViewController as? ARProfileViewController {
            if amFollowing {
                UserClient.shared.unFollow(uuid: self.uuid, success: {
                    self.amFollowing = false
                    parentViewController.setFollowUnFollowButton(self.button, amFollowing: self.amFollowing)
                }, failure: { error in })
            } else {
                UserClient.shared.follow(uuid: self.uuid, success: {
                    self.amFollowing = true
                    parentViewController.setFollowUnFollowButton(self.button, amFollowing: self.amFollowing)
                }, failure: { error in })
            }
        }
    }
}
