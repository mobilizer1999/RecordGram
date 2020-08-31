//
//  ProducerBeatsTableViewCell.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/8/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit

class ProducerBeatsTableViewCell: BeatTableViewCell {

    @IBOutlet weak var indexLabel: UILabel!
    @IBOutlet weak var beatDurationLabel: UILabel!
    @IBOutlet weak var genreLabel: UILabel!

    override func setup(with beat: Beat) {
        super.setup(with: beat)
        if let genreName = beat.genre?.name {
            genreLabel.text = genreName
        } else {
            genreLabel.text = "██"
        }
    }

    override func clear() {
        super.clear()
        genreLabel.text = "██"
    }
}
