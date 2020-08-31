//
//  ProducerSearchCell.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/21/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.

import UIKit
import SwiftyJSON

class ProducerSearchCell: SearchCell {

    @IBOutlet weak var producerSearchImageView: RoundImageView!
    @IBOutlet weak var producerInfoLabel: UILabel!

    let placeholder = UIImage(named: "profile_placeholder")

    override func load() {
        producerInfoLabel.text = ""
        producerSearchImageView.image = placeholder
    }

    override func load(_ data: JSON) {
        producerInfoLabel.text = data["text"].string
        self.producerSearchImageView.kf.setImage(with: URL(string: data["thumbnail"].stringValue), placeholder: self.placeholder)
    }
}
