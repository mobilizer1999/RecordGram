//
//  ChatInviteTableViewCell.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 10/11/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.

import UIKit

class ChatInviteTableViewCell: UITableViewCell {

    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var picture: RoundImageView!
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
