//
//  ContestCollectionCellCollectionViewCell.swift
//  RecordGram
//
//  Created by Ignacio Oroná on 02/02/2018.
//  Copyright © 2018 Meridian Inc. All rights reserved.
//

import UIKit

class ContestCollectionCellCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var titleLabel:      UILabel!
    @IBOutlet weak var subtitleLabel:   UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
}
