//
//  MessagesTableViewCell.swift
//  RecordGram
//
//  Created by Dewayne Perry on 10/5/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.

import UIKit

class MessagesTableViewCell: UITableViewCell {

    @IBOutlet weak var messageProfilePic: UIImageView!
    
    @IBOutlet weak var messageName: UILabel!
    
    @IBOutlet weak var messagePreviewText: UILabel!
    
    @IBOutlet weak var messageDate: UILabel!
    @IBOutlet weak var verifiedImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
