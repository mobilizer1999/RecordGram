//
//  FindFollowHeaderTableViewCell.swift
//  RecordGram
//
//  Created by Mauro Taroco on 6/12/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit

enum FindFollowHeaderType {
    case header
    case facebook
    case twitter
    case phoneContact
    case nearby
    case randomInvite
    
    func loadImageAndText() -> (String, NSAttributedString?, UIImage?) {
        switch self {
        case .header:
            return (NSLocalizedString("Grow Your Friend Circle", comment: "Find and Follow"), nil, nil)
        case .facebook:
            return (NSLocalizedString("Facebook", comment: "Find and Follow"), nil, UIImage(named: "_@2x -facebook"))
        case .twitter:
            return (NSLocalizedString("Twitter", comment: "Find and Follow"), nil, UIImage(named: "_@2x -twitter"))
        case .phoneContact:
            return (NSLocalizedString("Phone Contacts", comment: "Find and Follow"), nil, UIImage(named: "_@2x -phone_contacts"))
        case .nearby:
            let nearbyAttribute = [NSAttributedStringKey.foregroundColor: UIColor.init(hex: "3F3F3F"), NSAttributedStringKey.font: UIFont.systemFont(ofSize: 18)]
            let radiusValueAttribute = [NSAttributedStringKey.foregroundColor: UIColor.init(hex: "3F3F3F"), NSAttributedStringKey.font: UIFont.systemFont(ofSize: 15)]
            let radiusAttribute = [NSAttributedStringKey.foregroundColor: UIColor.init(hex: "7F7F7F"), NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14)]

            let partOne = NSMutableAttributedString(string: NSLocalizedString("Nearby", comment: "Find and Follow") + "\n", attributes: nearbyAttribute)
            let partTwo = NSMutableAttributedString(string: NSLocalizedString("Radius is ", comment: "Find and Follow"), attributes: radiusAttribute)
            let miles = String(format: NSLocalizedString("%@ Miles, ", comment: "Find and Follow"), UserDefaults.nearbyMiles())
            let partThree = NSMutableAttributedString(string: miles, attributes: radiusValueAttribute)
            let partFour = NSMutableAttributedString(string: NSLocalizedString("Tap to change", comment: "Find and Follow"), attributes: radiusAttribute)

            let combination = NSMutableAttributedString()
            
            combination.append(partOne)
            combination.append(partTwo)
            combination.append(partThree)
            combination.append(partFour)

            return (NSLocalizedString("Nearby", comment: "Find and Follow"), combination, UIImage(named: "_@2x -nearby"))
        case .randomInvite:
            let titleAttribute = [NSAttributedStringKey.foregroundColor: UIColor.init(hex: "3F3F3F"), NSAttributedStringKey.font: UIFont.systemFont(ofSize: 18)]
            let subtitleAttribute = [NSAttributedStringKey.foregroundColor: UIColor.init(hex: "7F7F7F"), NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14)]

            let partOne = NSMutableAttributedString(string: NSLocalizedString("Random Invite", comment: "Find and Follow") + "\n", attributes: titleAttribute)
            let partTwo = NSMutableAttributedString(string: NSLocalizedString("(Skype, Message, Email and LinkedIn etc.)", comment: "Find and Follow"), attributes: subtitleAttribute)
            
            let combination = NSMutableAttributedString()
            combination.append(partOne)
            combination.append(partTwo)
            return (NSLocalizedString("Random Invite", comment: "Find and Follow"), combination, UIImage(named: "_@2x -random"))
        }
    }
}

class FindFollowHeaderTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    func setupCell(typeCell: FindFollowHeaderType) {
        let values = typeCell.loadImageAndText()
        
        if values.1 != nil {
            titleLabel.attributedText = values.1
        } else {
            titleLabel.text = values.0
        }
        
        if values.2 != nil {
            logoImageView.image = values.2
            logoImageView.isHidden = false
        } else {
            logoImageView.isHidden = true
        }
    }
}
