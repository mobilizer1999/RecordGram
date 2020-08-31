//
//  CommentTableViewCell.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/19/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit

class CommentTableViewCell: UITableViewCell {
    @IBOutlet weak var imgProfile: UIImageView!
    @IBOutlet weak var imgVerified: UIImageView!
    @IBOutlet weak var lblUsername: UILabel!
    @IBOutlet weak var lblBody: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
