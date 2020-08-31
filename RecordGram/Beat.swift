//
//  Beat.swift
//  RecordGram
//
//  Created by Hugo Prione on 18/09/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import Foundation

class Beat: Media {
    var uuid: String?
    var name: String?
    var description: String?
    var url: URL?
    var producer: Producer?
    var genre: Genre?
    var image: URL?
    var price: Int?
    var isPublic: Bool?
    var user: User?
    var purchased: Bool?
    var isLiked: Bool?
    var comments: Int?
    var views: Int?

    var needToPurchase: Bool {
        if !(purchased ?? false), let price = price, price > 0 {
            return true
        } else {
            return false
        }
    }

    var canBuy: Bool {
        if let credits = Int(UserClient.shared.get("credits") ?? "0"), credits >= price! {
            return true
        } else {
            return false
        }
    }
}
