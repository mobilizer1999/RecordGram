//
//  Video.swift
//  RecordGram
//
//  Created by Hugo Prione on 20/11/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import CoreLocation

class Video: Media {
    var uuid: String?
    var name: String?
    var description: String?
    var url: URL?
    var genre: Genre?
    var image: URL?
    var coordinate: CLLocationCoordinate2D?
    var isPublic: Bool?
    var user: User?
    var beat: Beat?
    var gif: URL?
    var thumb: URL?
    var contest: Contest?
    var isLiked: Bool?
    var comments: Int?
    var views: Int?
}
