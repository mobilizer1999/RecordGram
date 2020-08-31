//
//  RecentSearchCell.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/21/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.

import UIKit
import SwiftyJSON

class RecentSearchCell: SearchCell {

    @IBOutlet weak var recentSearchImageView: RoundImageView!
    @IBOutlet weak var recentTypeLabel: UILabel!
    @IBOutlet weak var recentInfoLabel: UILabel!

    let userPlaceholder = UIImage(named: "profile_placeholder")
    let mediaPlaceholder = UIImage(named: "media_placeholder")

    override func load() {
        uuid = ""
        recentTypeLabel.text = ""
        recentInfoLabel.text = ""
        recentSearchImageView.image = userPlaceholder
    }

    override func load(_ data: JSON) {
        uuid = data["uuid"].string!
        recentInfoLabel.text = data["text"].string
        switch data["type"].string! {
        case "beats":
            recentTypeLabel.text = "Music"
            self.recentSearchImageView.kf.setImage(with: URL(string: data["thumbnail"].stringValue), placeholder: self.mediaPlaceholder)
        case "users":
            if data["is_producer"].boolValue {
                recentTypeLabel.text = NSLocalizedString("Producer", comment: "Recent search")
            } else {
                recentTypeLabel.text = NSLocalizedString("User", comment: "Recent search")
            }
            self.recentSearchImageView.kf.setImage(with: URL(string: data["thumbnail"].stringValue), placeholder: self.userPlaceholder)
        case "songs":
            recentTypeLabel.text = NSLocalizedString("Song", comment: "Recent search")
            recentSearchImageView.image = mediaPlaceholder
        case "videos":
            recentTypeLabel.text = NSLocalizedString("Video", comment: "Recent search")
            recentSearchImageView.image = mediaPlaceholder
            VideosClient.shared.get(uuid: uuid, success: { video in
                if let gif = video.gif, video.uuid == self.uuid {
                    self.recentSearchImageView.kf.setImage(with: gif, placeholder: self.mediaPlaceholder)
                }
            }, failure: { _ in })
        default:
            break
        }
    }
}
