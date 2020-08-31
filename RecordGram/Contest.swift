//
//  Contest.swift
//  RecordGram
//
//  Created by Hugo Prione on 15/01/18.
//  Copyright © 2018 Meridian Inc. All rights reserved.
//

import UIKit

struct Contest {
    var uuid: String?
    var title: String?
    var hashtag: String?
    var thumbnail: URL?
    var type: ContestType?
    var startDate: Date?
    var endDate: Date?
    var winnerId: Int?
    var winnerType: String?
    var gif: String?
    var winner: ContestWinner?
    
    mutating func setContestType(_ strType: String) {
        if (strType.elementsEqual(kContestTypeVideo)) {
            self.type = ContestType.video
        } else if(strType.elementsEqual(kContestTypeSong)) {
            self.type = ContestType.song
        }
        else if(strType.elementsEqual(kContestTypeOther)) {
            self.type = ContestType.other
        }
    }
}

enum ContestType {
    case video
    case song
    case other
}


struct ContestWinner {
    
    var shared: Int?
    var thumbnail: URL?
    var gif: String?
    
    var username: String?
    var profilePicture: String?
    var email: String?
    var bio: String?
    var password: String?
    var phoneNumber: String?
    var name: String?
    var uuid: String?
    
    var credits: Int?
    var coordinates: [String:Any]?
    var followerCount: Int?
    var followingCount: Int?
    var isFavorite: Bool?
}
