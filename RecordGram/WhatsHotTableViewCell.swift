//
//  WhatsHotTableViewCell.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/6/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit

class WhatsHotTableViewCell: BeatTableViewCell {

    @IBOutlet weak var producerImage: UIImageView!
    @IBOutlet weak var producerLabel: UILabel!
    @IBOutlet weak var genreLabel: UILabel!

    let placeholder = #imageLiteral(resourceName:"media_placeholder")

    override func setup(with beat: Beat) {
        super.setup(with: beat)
        if let image = beat.image {
            producerImage.kf.setImage(with: image, placeholder: placeholder)
        } else if let image = beat.producer?.profilePicture {
            producerImage.kf.setImage(with: image, placeholder: placeholder)
        } else {
            producerImage.image = placeholder
        }
        if let producerName = beat.producer?.name {
            producerLabel.text = producerName
        } else {
            producerLabel.text = "█████"
        }
        if let genreName = beat.genre?.name {
            genreLabel.text = genreName
        } else {
            genreLabel.text = "██"
        }
    }

    override func clear() {
        super.clear()
        producerImage.image = placeholder
        producerLabel.text = "█████"
        genreLabel.text = "██"
    }
}
