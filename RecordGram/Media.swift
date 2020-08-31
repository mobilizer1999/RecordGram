//
//  Media.swift
//  RecordGram
//
//  Created by Hugo Prione on 27/11/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import Foundation

protocol Media {
    var uuid: String? { get set }
    var name: String? { get set }
    var description: String? { get set }
    var url: URL? { get set }
    var genre: Genre? { get set }
    var image: URL? { get set }
    var isPublic: Bool? { get set }
    var user: User? { get set }
    var isLiked: Bool? { get set }
    var amOwner: Bool { get }
    var comments: Int? { get set }
    var views: Int? { get set }
}

extension Media {
    var amOwner: Bool {
        return user?.uuid == UserClient.shared.uuid()
    }
}
