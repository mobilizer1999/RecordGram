//
//  SongCollectionViewCell.swift
//  RecordGram
//
//  Created by Hugo Prione on 21/09/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.

import UIKit
import Gifu

class SongCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var producerLabel: UILabel!
    @IBOutlet weak var thumbnailImageView: UIImageView?

    let mediaPlaceholder = #imageLiteral(resourceName:"media_placeholder")
    let profilePlaceholder = #imageLiteral(resourceName:"profile_placeholder")

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func setup(with song: Song) {
        titleLabel.text = song.name ?? ""
        nameLabel.text = song.user?.username ?? song.user?.name ?? ""
        producerLabel.text = song.beat?.producer?.name ?? ""

        thumbnailImageView?.layer.cornerRadius = 0
        if let thumbnail = song.thumbnail {
            thumbnailImageView?.kf.setImage(with: thumbnail, placeholder: mediaPlaceholder)
        } else if let profilePicture = song.user?.picture {
            thumbnailImageView?.kf.setImage(with: profilePicture, placeholder: profilePlaceholder)
            thumbnailImageView?.layer.cornerRadius = 34.5
            thumbnailImageView?.clipsToBounds = true
        } else {
            thumbnailImageView?.image = mediaPlaceholder
        }
    }

    func clear() {
        titleLabel.text = "███"
        nameLabel.text = "█████"
        producerLabel.text = "█████"
        thumbnailImageView?.image = mediaPlaceholder
        thumbnailImageView?.layer.cornerRadius = 0
    }
}
