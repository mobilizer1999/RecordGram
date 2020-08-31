//
//  FindFollowTableViewCell.swift
//  RecordGram
//
//  Created by Mauro Taroco on 4/12/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit

enum FindFollowRow {
    case inviteFacebook
    case findFollowFacebook
    case inviteFollowTwitter
    case inviteFollowContact
    case inviteFollowNearby
    case invisibleToUsers
    case inviteRecordGram
    
    func loadText() -> String {
        switch self {
        case .inviteFacebook:
            return NSLocalizedString("Invite Facebook Friends", comment: "Find and Follow")
        case .findFollowFacebook:
            return NSLocalizedString("Find and Follow Facebook Friends", comment: "Find and Follow")
        case .inviteFollowTwitter:
            return NSLocalizedString("Find and Follow Facebook Friends", comment: "Find and Follow")
        case .inviteFollowContact:
            return NSLocalizedString("Invite or Follow Your Contacts", comment: "Find and Follow")
        case .inviteFollowNearby:
            return NSLocalizedString("Invite or Follow Your Contacts", comment: "Find and Follow")
        case .invisibleToUsers:
            return UserDefaults.isVisibleNearby() ? NSLocalizedString("Visible to Other Users", comment: "Find and Follow") : NSLocalizedString("Invisible to Other Users", comment: "Find and Follow")
        case .inviteRecordGram:
            return NSLocalizedString("Invite to Join", comment: "Find and Follow")
        }
    }
}

class FindFollowTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    func setupCell(typeCell: FindFollowRow) {
        titleLabel.text = typeCell.loadText()
    }

}
