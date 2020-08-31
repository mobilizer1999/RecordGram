//
//  User.swift
//  RecordGram
//
//  Created by Hugo Prione on 18/09/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import Foundation

struct User {
    var uuid: String?
    var name: String?
    var username: String?
    var picture: URL?
    var reciprocal: Bool?
    var amFollowing: Bool?
    var followsMe: Bool?
    var isANR: Bool?
    var isVisibleInNearby: Bool?
    var isVerified: Bool?

    func toString() -> String? {
        if let username = username {
            return "@\(username)"
        }
        return name
    }
}
