//
//  VideoSearchCell.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/21/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.

import UIKit
import Kingfisher
import SwiftyJSON

class VideoSearchCell: SearchCell {

    @IBOutlet weak var videoSearchImageView: UIImageView!

    let placeholder = UIImage(named: "media_placeholder")

    override func load() {
        uuid = ""
        self.videoSearchImageView.image = placeholder
    }

    override func load(_ data: JSON) {
        uuid = data["uuid"].string!
        if let thumbnail = data["thumbnail"].string {
            self.videoSearchImageView.kf.setImage(with: URL(string: thumbnail), placeholder: self.placeholder)
        } else {
            self.videoSearchImageView.image = placeholder
            VideosClient.shared.get(uuid: uuid, success: { video in
                if let gif = video.gif, video.uuid == self.uuid {
                    self.videoSearchImageView.kf.setImage(with: gif, placeholder: self.placeholder)
                }
            }, failure: { _ in })
        }
    }
}
