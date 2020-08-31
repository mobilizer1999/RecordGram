//
//  SongSearchCell.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/21/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.

import UIKit
import SwiftyJSON

class SongSearchCell: SearchCell {

    @IBOutlet weak var songSearchImageView: RoundImageView!
    @IBOutlet weak var songInfoLabel: UILabel!

    override func load() {
        songInfoLabel.text = ""
    }

    override func load(_ data: JSON) {
        songInfoLabel.text = data["text"].string
        // Song has no thumbnail image
    }
}
