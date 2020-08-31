//
//  GenresClient.swift
//  RecordGram
//
//  Created by Hugo Prione on 30/10/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.

import UIKit
import Alamofire
import SwiftyJSON

class GenresClient: Client {
    static let shared = GenresClient()

    enum Router: URLRequestConvertible {
        case all

        var method: HTTPMethod {
            switch self {
            case .all:
                return .get
            }
        }

        var endpoint: String {
            switch self {
            case .all:
                return "genres"
            }
        }

        func asURLRequest() throws -> URLRequest {
            var urlRequest = URLRequest(url: try HomeFeedClient.shared.apiUrl(endpoint: endpoint).asURL())
            urlRequest.httpMethod = method.rawValue

            switch self {
            case .all:
                urlRequest = try URLEncoding.default.encode(urlRequest, with: [
                    "page": 1
                ])
            }

            return urlRequest
        }
    }

    func all(success: @escaping (_ response: [Genre]?) -> Void, failure: @escaping (_ error: NSError) -> Void) {
//        defaultRequest(Router.all, success: { (json) in
//            let genres = json["data"].array?.map({ GenresClient.genre(fromJson: $0) })

//            success(genres)
//        }, failure: failure)
        success([
            Genre(uuid:"2d64ac48-03fa-4b7a-ad47-4a5a498901dc", name: NSLocalizedString("Hip Hop", comment: "Genre"), image: nil),
            Genre(uuid:"c5439741-4dd6-40cb-8a0f-e412f7262180", name: NSLocalizedString("R&B", comment: "Genre"), image: nil),
            Genre(uuid:"d770943f-b6b7-4ec5-82b9-cb670a8789ab", name: NSLocalizedString("Pop", comment: "Genre"), image: nil),
            Genre(uuid:"bc5ea7f7-ae19-4c67-b73f-d6e7802f24a1", name: NSLocalizedString("Reggae", comment: "Genre"), image: nil),
            Genre(uuid:"1e342bd7-c621-4de9-a2c8-4dcf0c9f39bc", name: NSLocalizedString("Latin", comment: "Genre"), image: nil),
            Genre(uuid:"e4377893-5e0d-40e5-ab0c-4df3011bb23d", name: NSLocalizedString("Electro", comment: "Genre"), image: nil),
            Genre(uuid:"71174e0f-354e-4af6-a3c8-c2de7dcb2b01", name: NSLocalizedString("Bollywood", comment: "Genre"), image: nil),
            Genre(uuid:"89b26b52-aeb2-4c09-814b-48128770385e", name: NSLocalizedString("AfroBeat", comment: "Genre"), image: nil),
            Genre(uuid:"0c0bf50f-a3f2-4955-8e96-9c1b1ff235e0", name: NSLocalizedString("Contests", comment: "Genre"), image: nil),
            Genre(uuid:"7171a2f7-af41-4c21-961d-afffc3f40529", name: NSLocalizedString("Country", comment: "Genre"), image: nil),
        ])
        
    }

    static func genre(fromJson json: JSON) -> Genre {
        var genre = Genre()
        genre.uuid = json["uuid"].string
        genre.name = json["name"].string
        genre.image = json["image"].string

        return genre
    }
}
