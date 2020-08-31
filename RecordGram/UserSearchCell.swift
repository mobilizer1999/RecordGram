//
//  UserSearchCell.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/21/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.

import UIKit
import SwiftyJSON

class UserSearchCell: SearchCell {

    @IBOutlet weak var userSearchImageView: RoundImageView!
    @IBOutlet weak var userInfoLabel: UILabel!

    let placeholder = UIImage(named: "profile_placeholder")

    override func load() {
        userInfoLabel.text = ""
        self.userSearchImageView.image = placeholder
    }

    override func load(_ data: JSON) {
        userInfoLabel.text = data["text"].string
        self.userSearchImageView.kf.setImage(with: URL(string: data["thumbnail"].stringValue), placeholder: self.placeholder)
    }
}
