//
//  UserDefaultExtension.swift
//  RecordGram
//
//  Created by Mauro Taroco on 4/12/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import Foundation

extension UserDefaults {

    class func setObject(value: Any?, key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
    
    class func setNearbyMiles(miles: String) {
        setObject(value: miles, key: kPreferredNearbySearchDistance)
    }
    
    class func nearbyMiles() -> String {
        if let value = UserDefaults.standard.string(forKey: kPreferredNearbySearchDistance) {
            return value
        }
        UserDefaults.setNearbyMiles(miles: "5")
        return "5"
    }
    
    class func isVisibleNearby() -> Bool {
        return UserDefaults.standard.bool(forKey: kVisibleInnearby)
    }
    
    class func setCoordinate(latitude: String, longitude: String) {
        UserDefaults.setObject(value: latitude, key: kLatitude)
        UserDefaults.setObject(value: longitude, key: kLongitude)
    }
}
