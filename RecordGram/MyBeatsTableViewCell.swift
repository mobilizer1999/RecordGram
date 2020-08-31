//
//  MyBeatsTableViewCell.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/9/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit

class MyBeatsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var lblPosition: UILabel!
    @IBOutlet weak var imgProducer: UIImageView!
    @IBOutlet weak var lblBeatName: UILabel!
    @IBOutlet weak var lblProducerName: UILabel!
    @IBOutlet weak var lblGenreName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
