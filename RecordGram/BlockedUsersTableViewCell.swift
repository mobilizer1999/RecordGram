//
//  BlockedUsersTableViewCell.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/8/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit

class BlockedUsersTableViewCell: UITableViewCell {

    var uuid: String!

    @IBOutlet weak var imgProfile: RoundImageView!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var btnToggleBlock: RoundButton!

    @IBAction func didTabButton(_ sender: Any) {
        if self.btnToggleBlock.title(for: .normal) == NSLocalizedString("UNBLOCK", comment: "User action") {
            UserClient.shared.unblock(uuid, success: {
                self.btnToggleBlock.setTitle(NSLocalizedString("BLOCK", comment: "User action"), for: .normal)
            }, failure: { error in })
        } else {
            UserClient.shared.block(uuid, success: {
                self.btnToggleBlock.setTitle(NSLocalizedString("UNBLOCK", comment: "User action"), for: .normal)
            }, failure: { error in })
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
