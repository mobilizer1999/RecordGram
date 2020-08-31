//
//  UserFriend.swift
//  RecordGram
//
//  Created by Mauro Taroco on 12/12/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import Foundation
import UIKit

struct UserFriend {
    var uuid: String?
    var name: String?
    var username: String?
    var email: String?
    var image: Data?
    var profileImageUrl: String?
    var screenName: String = ""
    //var isSelectedForInvitation: Bool = false
    var followsMe: Bool? = false
    var following: Bool? = false
    var isANR: Bool? = false
    var isVerifiedUser: Bool? = false
    
    public init (uuid: String?, name: String?, username: String?, email: String?, image: Data?, profileImageUrl: String?, screenName: String = "", followsMe: Bool? = true, following: Bool? = false, isANR: Bool? = false, isVerifiedUser: Bool? = false) {
        self.uuid = uuid
        self.name = name
        self.username = username
        self.email = email
        self.image = image
        self.profileImageUrl = profileImageUrl
        self.screenName = screenName
        self.followsMe = followsMe
        self.following = following
        self.isANR = isANR
        self.isVerifiedUser = isVerifiedUser
    }
    
    public func displayName() -> String {
        if let nameU = self.name, nameU.count > 0 {
            return nameU
        }
        else {
            return self.username ?? ""
        }
    }
    
    func identifierForInvitation(userFriendsType: UserFriendType) -> String {
        if userFriendsType == .twitter {
            return screenName
        }
        else if userFriendsType == .phoneContact {
            return email ?? name ?? ""
        }
        
        return email ?? name ?? ""
    }
}
