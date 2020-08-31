//
//  Song.swift
//  RecordGram
//
//  Created by Mauro Taroco on 11/22/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import CoreLocation
import UIKit

class Song: Media {
    var uuid: String?
    var name: String?
    var description: String?
    var url: URL?
    var genre: Genre?
    var image: URL?
    var coordinate: CLLocationCoordinate2D?
    var isPublic: Bool?
    var gif: URL?
    var thumbnail: URL?
    var thumbnailImage: UIImage?
    var beat: Beat?
    var user: User?
    var contest: Contest?
    var isLiked: Bool?
    var comments: Int?
    var views: Int?
}
