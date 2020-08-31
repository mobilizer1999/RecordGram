//
//  NotificationSettingsTableViewController.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/27/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.

import UIKit

class NotificationSettingsTableViewController: UITableViewController, ErrorHandler {

    @IBOutlet weak var allNotifications: UISwitch!
    @IBOutlet weak var newMessages: UISwitch!
    @IBOutlet weak var beatLike: UISwitch!
    @IBOutlet weak var songLike: UISwitch!
    @IBOutlet weak var songComment: UISwitch!
    @IBOutlet weak var songMention: UISwitch!
    @IBOutlet weak var songCommentMention: UISwitch!
    @IBOutlet weak var songUpload: UISwitch!
    @IBOutlet weak var videoLike: UISwitch!
    @IBOutlet weak var videoComment: UISwitch!
    @IBOutlet weak var videoMention: UISwitch!
    @IBOutlet weak var videoCommentMention: UISwitch!
    @IBOutlet weak var videoUpload: UISwitch!
    @IBOutlet weak var userFollow: UISwitch!
    @IBOutlet weak var commentLike: UISwitch!
    @IBOutlet weak var admin: UISwitch!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("Notification Settings", comment: "Notification Settings")
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName:"closeButtonWhite"), style: .plain, target: self, action: #selector(NotificationSettingsTableViewController.onBackButton))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Save", comment: "Menu"), style: .plain, target: self, action: #selector(NotificationSettingsTableViewController.onSaveButton))
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        NotificationsClient.shared.preferences(success: { preferences in
            self.setToggles(with: preferences)
        }, failure: { error in
            self.presentErrorDialog(error: error)
        })
    }

    @objc func onBackButton() {
        self.dismiss(animated: true, completion: nil)
    }

    @objc func onSaveButton() {
        let parameters = [
            "beat_like": beatLike.isOn,
            "comment_like": commentLike.isOn,
            "song_like": songLike.isOn,
            "video_like": videoLike.isOn,
            "song_comment": songComment.isOn,
            "video_comment": videoComment.isOn,
            "song_mention": songMention.isOn,
            "song_comment_mention": songCommentMention.isOn,
            "video_mention": videoMention.isOn,
            "video_comment_mention": videoCommentMention.isOn,
            "derivative_song_upload": songUpload.isOn,
            "derivative_video_upload": videoUpload.isOn,
            "admin": admin.isOn
            // TODO New Messages
            // TODO User Follow
        ]
        NotificationsClient.shared.savePreferences(parameters: parameters, success: {
            self.dismiss(animated: true, completion: nil)
        }, failure: { error in
            self.presentErrorDialog(error: error)
        })
    }

    func setToggles(with preferences: NotificationPreferences) {

        beatLike.setOn(preferences.beatLike ?? false, animated: true)
        songLike.setOn(preferences.songLike ?? false, animated: true)
        songComment.setOn(preferences.songComment ?? false, animated: true)
        songMention.setOn(preferences.songMention ?? false, animated: true)
        songCommentMention.setOn(preferences.songCommentMention ?? false, animated: true)
        songUpload.setOn(preferences.derivativeSongUpload ?? false, animated: true)
        videoLike.setOn(preferences.videoLike ?? false, animated: true)
        videoComment.setOn(preferences.videoComment ?? false, animated: true)
        videoMention.setOn(preferences.videoMention ?? false, animated: true)
        videoCommentMention.setOn(preferences.videoCommentMention ?? false, animated: true)
        videoUpload.setOn(preferences.derivativeVideoUpload ?? false, animated: true)
        commentLike.setOn(preferences.commentLike ?? false, animated: true)
        admin.setOn(preferences.admin ?? false, animated: true)
        // TODO New Messages
        // TODO User Follow

        setAllNotificationToggle()
    }

    func setAllNotificationToggle() {
        let shouldSetAllNotifications = newMessages.isOn && beatLike.isOn && songLike.isOn && songComment.isOn
                && songMention.isOn && songCommentMention.isOn && songUpload.isOn && videoLike.isOn && videoComment.isOn
                && videoMention.isOn && videoCommentMention.isOn && videoUpload.isOn && userFollow.isOn
                && commentLike.isOn && admin.isOn

        allNotifications.setOn(shouldSetAllNotifications, animated: true)
    }

    @IBAction func didToggleAllNotifications() {
        newMessages.setOn(allNotifications.isOn, animated: true)
        beatLike.setOn(allNotifications.isOn, animated: true)
        songLike.setOn(allNotifications.isOn, animated: true)
        songComment.setOn(allNotifications.isOn, animated: true)
        songMention.setOn(allNotifications.isOn, animated: true)
        songCommentMention.setOn(allNotifications.isOn, animated: true)
        songUpload.setOn(allNotifications.isOn, animated: true)
        videoLike.setOn(allNotifications.isOn, animated: true)
        videoComment.setOn(allNotifications.isOn, animated: true)
        videoMention.setOn(allNotifications.isOn, animated: true)
        videoCommentMention.setOn(allNotifications.isOn, animated: true)
        videoUpload.setOn(allNotifications.isOn, animated: true)
        userFollow.setOn(allNotifications.isOn, animated: true)
        commentLike.setOn(allNotifications.isOn, animated: true)
        admin.setOn(allNotifications.isOn, animated: true)
    }

    @IBAction func didToggle() {
        setAllNotificationToggle()
    }
}
