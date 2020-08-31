//
//  FriendTableViewCell.swift
//  RecordGram
//
//  Created by Mauro Taroco on 7/12/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit

protocol FriendTableViewCellDelegate {
    func isFriendSelectedForInvitation(_ friend: UserFriend) -> Bool
}

class FriendTableViewCell: UITableViewCell {

    @IBOutlet weak var friendProfileImageView: UIImageView!
    @IBOutlet weak var friendNameLabel: UILabel!
    @IBOutlet weak var addToInviteButton: UIButton!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var verifiedImageView: UIImageView!

    var delegate: FriendTableViewCellDelegate?
    var placeholder = #imageLiteral(resourceName: "profile_placeholder")

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func setupCell(withFriend friend: UserFriend, actionType: UserFriendActionType) {

        verifiedImageView.isHidden = true

        if actionType == .invite {
            friendNameLabel.attributedText = setAttributedUserName(withUserFriend: friend)

            addToInviteButton.isHidden = false
            addToInviteButton.isSelected = delegate?.isFriendSelectedForInvitation(friend) ?? false

            followButton.isHidden = true

            setProfileImageOn(friendProfileImageView, withData: friend.image)
        } else {
            friendNameLabel.text = friend.displayName()

            addToInviteButton.isHidden = true

            followButton.isHidden = false
            followButton.isSelected = friend.following!

            setProfileImageOn(friendProfileImageView, forURLString: friend.profileImageUrl)

            if friend.isVerifiedUser! {
                verifiedImageView.isHidden = false
            }
        }
    }

    func setProfileImageOn(_ profileImageView: UIImageView, forURLString urlStr: String?) {
        guard let urlStr = urlStr, urlStr.count > 0 else {
            profileImageView.image = placeholder
            return
        }

        profileImageView.kf.setImage(with: URL(string: urlStr), placeholder: placeholder)
    }

    func setProfileImageOn(_ profileImageView: UIImageView, withData imageData: Data?) {
        guard let imageData = imageData else {
            profileImageView.image = placeholder
            return
        }

        profileImageView.image = UIImage(data: imageData)
    }

    func setAttributedUserName(withUserFriend userFriend: UserFriend) -> NSMutableAttributedString {
        let titleStr = NSMutableAttributedString(string: "", attributes: nil)
        titleStr.append(NSAttributedString(string: userFriend.displayName(), attributes: [NSAttributedStringKey.foregroundColor: UIColor.init(hex: "3F3F3F"), NSAttributedStringKey.font: UIFont(name: "HelveticaNeue", size: 15)]))
        titleStr.append(NSAttributedString(string: """
    
    
    """, attributes: nil))
        titleStr.append(NSAttributedString(string: userFriend.email as? String ?? "", attributes: [NSAttributedStringKey.foregroundColor: UIColor.init(hex: "7F7F7F"), NSAttributedStringKey.font: UIFont(name: "HelveticaNeue", size: 11)]))
        return titleStr
    }
}

