//
//  RecordGramMessageTableViewCell.swift
//  RecordGram
//
//  Created by Nicolas Gonzalez on 3/14/18.
//  Copyright © 2018 Meridian Inc. All rights reserved.
//

import UIKit

class RecordGramMessageTableViewCell: UITableViewCell {

    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var body: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func setupCell(with notification: RGNotification) {

        if notification.read == true {
            backgroundColor = UIColor.clear
        } else {
            backgroundColor = UIColor.unreadColor;
        }

        body.text = notification.body

        if let timestamp = notification.timestamp {
            date.text = timestamp.timeAgo
        }
    }
}
