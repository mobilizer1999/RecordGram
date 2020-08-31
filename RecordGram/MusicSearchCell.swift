//
//  MusicSearchCell.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/21/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.

import UIKit
import SwiftyJSON

class MusicSearchCell: SearchCell {

    @IBOutlet weak var musicSearchImageView: RoundImageView!
    @IBOutlet weak var musicInfoLabel: UILabel!

    let placeholder = UIImage(named: "media_placeholder")

    override func load() {
        musicInfoLabel.text = ""
        self.musicSearchImageView.image = placeholder
    }

    override func load(_ data: JSON) {
        musicInfoLabel.text = data["text"].string
        self.musicSearchImageView.kf.setImage(with: URL(string: data["thumbnail"].stringValue), placeholder: self.placeholder)
    }
}