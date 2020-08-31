//
//  InstagramActivity.swift
//  RecordGram
//
//  Created by Hugo Prione on 06/12/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit

protocol CustomActivityDelegate {
    func prepare(activity: UIActivity, withActivityItems activityItems: [Any])
}

class InstagramActivity: UIActivity {
    var delegate: CustomActivityDelegate?
    
    override class var activityCategory: UIActivityCategory {
        return .share
    }
    
    override var activityType: UIActivityType? {
        return UIActivityType.init("com.recorgramapp.sharingactivityinstagram")
    }
    
    override var activityTitle: String? {
        return NSLocalizedString("Instagram", comment: "Share activity")
    }
    
    override var activityImage: UIImage? {
        return #imageLiteral(resourceName: "instagram_logo")
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        delegate?.prepare(activity: self, withActivityItems: activityItems)
    }
}
