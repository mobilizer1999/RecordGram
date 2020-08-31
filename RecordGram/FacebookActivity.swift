//
//  FacebookActivity.swift
//  RecordGram
//
//  Created by Hugo Prione on 07/12/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit

class FacebookActivity: UIActivity {
    var delegate: CustomActivityDelegate?
    
    override class var activityCategory: UIActivityCategory {
        return .share
    }
    
    override var activityType: UIActivityType? {
        return UIActivityType.init("com.recorgramapp.sharingactivityfacebook")
    }
    
    override var activityTitle: String? {
        return NSLocalizedString("Facebook", comment: "Share activity")
    }
    
    override var activityImage: UIImage? {
        return #imageLiteral(resourceName: "facebook_icon")
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        delegate?.prepare(activity: self, withActivityItems: activityItems)
    }
}
