//
//  NotificationTableViewCell.swift
//  RecordGram
//
//  Created by Mauro Taroco on 1/16/18.
//  Copyright © 2018 Meridian Inc. All rights reserved.
//

import UIKit


class NotificationTableViewCell: UITableViewCell {

    @IBOutlet weak var dateAddedLbl: UILabel!
    @IBOutlet weak var messageLbl: UILabel!
    @IBOutlet weak var userImg: UIImageView!
    @IBOutlet weak var usernameButton: UIButton!
    @IBOutlet weak var verifiedImageView: UIImageView!
    
    var notification: RGNotification?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func resetCell() {
        self.notification = nil
        backgroundColor = UIColor.clear
        usernameButton.isHidden = true
        messageLbl.text = ""
        dateAddedLbl.text = ""
        userImg.image = #imageLiteral(resourceName:"color-logo")
    }

    func setupCell(with notification: RGNotification) {
        self.notification = notification

        if notification.read == true {
            backgroundColor = UIColor.clear
        } else {
            backgroundColor = UIColor.unreadColor;
        }

        if let username = notification.sender?.username, let notificationType = notification.type {
            usernameButton.isHidden = false
            usernameButton.setTitle(username, for: .normal)
            switch notificationType {
            case .commentLike:
                messageLbl.text = NSLocalizedString(" liked your comment!", comment: "Notification")
            case .beatLike:
                messageLbl.text = NSLocalizedString(" liked your beat!", comment: "Notification")
            case .songLike:
                messageLbl.text = NSLocalizedString(" liked your song!", comment: "Notification")
            case .videoLike:
                messageLbl.text = NSLocalizedString(" liked your video!", comment: "Notification")
            case .songComment:
                messageLbl.text = NSLocalizedString(" commented on your song!", comment: "Notification")
            case .videoComment:
                messageLbl.text = NSLocalizedString(" commented on your video!", comment: "Notification")
            case .songMention:
                messageLbl.text = NSLocalizedString(" mentioned you on a song!", comment: "Notification")
            case .videoMention:
                messageLbl.text = NSLocalizedString(" mentioned you on a video!", comment: "Notification")
            case .songCommentMention:
                messageLbl.text = NSLocalizedString(" mentioned you on a song comment!", comment: "Notification")
            case .videoCommentMention:
                messageLbl.text = NSLocalizedString(" mentioned you on a video comment!", comment: "Notification")
            case .derivativeSongUpload:
                messageLbl.text = NSLocalizedString(" uploaded a song with your beat!", comment: "Notification")
            case .derivativeVideoUpload:
                messageLbl.text = NSLocalizedString(" uploaded a video with your beat!", comment: "Notification")
            default:
                usernameButton.isHidden = true
                messageLbl.text = notification.body
            }
        } else {
            usernameButton.isHidden = true
            messageLbl.text = notification.body
        }

        if let timestamp = notification.timestamp {
            dateAddedLbl.text = timestamp.timeAgo
        }

        userImg.kf.setImage(with: notification.sender?.picture, placeholder: #imageLiteral(resourceName:"profile_placeholder"))

        verifiedImageView.isHidden = !(notification.sender?.isVerified ?? false)

        let tapGestureOnUserImage = UITapGestureRecognizer.init(target: self, action: #selector(tapOnNotificationUserImage))
        tapGestureOnUserImage.numberOfTapsRequired = 1
        userImg.addGestureRecognizer(tapGestureOnUserImage)
    }

    @objc func tapOnNotificationUserImage(recognizer: UITapGestureRecognizer) {
        goToProfile()
    }

    @IBAction func didTouchUsername() {
        goToProfile()
    }

    func goToProfile() {
        if let uuid = notification?.sender?.uuid {
            parentViewController?.goToProfile(uuid: uuid, arUser: notification?.sender?.isANR ?? false)
        }
    }
}
