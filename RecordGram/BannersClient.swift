//
//  BannersClient.swift
//  RecordGram
//
//  Created by Hugo Prione on 15/09/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class BannersClient: Client {
    static let shared = BannersClient()

    enum Router: URLRequestConvertible {
        case all
        case featured

        var method: HTTPMethod {
            switch self {
            case .all, .featured:
                return .get
            }
        }

        var endpoint: String {
            switch self {
            case .all:
                return "banners"
            case .featured:
                return "featured-feed"
            }
        }

        func asURLRequest() throws -> URLRequest {
            var urlRequest = URLRequest(url: try HomeFeedClient.shared.apiUrl(endpoint: endpoint).asURL())
            urlRequest.httpMethod = method.rawValue

            switch self {
            case .featured:
                urlRequest = try URLEncoding.default.encode(urlRequest, with: [
                    "page": "1",
                    "limit": "100"
                ])
            default:
                break
            }

            return urlRequest
        }
    }

    func all(success: @escaping (_ response: [(UIImage, String)]?) -> Void, failure: @escaping (_ error: NSError) -> Void) {
//        defaultRequest(Router.all, success: { (json) in
//            let banners = json["data"].array?.map({ BannersClient.banner(fromJson: $0) })
//
//            success(banners)
//        }, failure: failure)
        success([
            (#imageLiteral(resourceName: "GingerBread"), "2ac21b29-9a79-494f-8dc4-f3bfd3f1bcee"),
            (#imageLiteral(resourceName: "Streetrunner"), "7624f22f-9a27-4b72-97a6-6025adb9f485"),
            (#imageLiteral(resourceName: "Blackkout"), "60f9ae8c-8470-4bbd-af96-a1576bc84728"),
            (#imageLiteral(resourceName: "Earthquake"), "4ece60e1-2073-46ac-b734-2849cce7a9b7"),
            (#imageLiteral(resourceName: "noydb"), "08c718dd-9fe5-4d70-a40f-206f8eee8bb3"),
            (#imageLiteral(resourceName: "Piano"), "3c79218e-0c18-4bb4-a25d-87ac124c2878"),
            (#imageLiteral(resourceName: "haz"), "64f5dea0-2acb-47bd-bb84-5b11ee9a524b"),
            (#imageLiteral(resourceName: "Reazy Renegade"), "09d3737a-dc0f-4664-92e5-9519b8b41b4b"),
            (#imageLiteral(resourceName: "Mixtape Beats"), "d6f68c55-3e14-49a5-a1f8-e230c589cdf9"),
            (#imageLiteral(resourceName: "DamionMiami"), "c3939e7a-4336-48bc-9e5b-4ba3e8f1a5d5")
            ])
    }

    func featured(success: @escaping (_ response: [Any]?) -> Void, failure: @escaping (_ error: NSError) -> Void) {
//        defaultRequest(Router.featured, success: { json in
            var results: [Any] = []

//            let videos = json["data"].array?.map({ VideosClient.video(fromJson: $0) })

//            if let videos = videos, videos.count > 0 {
//                results.insert(contentsOf: videos, at: 0)
//            }

            ContestsClient.shared.all(success: { contests in
                if let contests = contests, contests.count > 0 {
                    results.insert(contentsOf: contests, at: 0)
                }
                
                results.insert(StaticBanner(path: Bundle.main.path(forResource: "Cre8torBanner1", ofType: "png")), at: 0)
                results.insert(StaticBanner(path: Bundle.main.path(forResource: "Cre8torBanner2", ofType: "png")), at: 1)
                results.insert(StaticBanner(path: Bundle.main.path(forResource: "Cre8torBanner3", ofType: "png")), at: 2)
                results.insert(StaticBanner(path: Bundle.main.path(forResource: "Cre8torBanner4", ofType: "png")), at: 3)
                
                success(results)
            }, failure: failure)
//        }, failure: failure)
    }

    static func banner(fromJson json: JSON) -> Banner {
        var banner = Banner()
        banner.image = json["image"].string
        banner.title = json["title"].string
        banner.content = json["content"].string
        banner.producers = json["producers"].arrayValue.map {
            ProducersClient.producer(fromJson: $0)
        }

        return banner
    }
}
