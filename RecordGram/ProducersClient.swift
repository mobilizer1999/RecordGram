//
//  ProducersClient.swift
//  RecordGram
//
//  Created by Hugo Prione on 15/09/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class ProducersClient: Client {
    static let shared = ProducersClient()

    enum Router: URLRequestConvertible {
        case all
        case get(page: Int)
        case beats(uuid: String, page: Int)

        static let limit = 15

        var method: HTTPMethod {
            switch self {
            case .all, .get, .beats:
                return .get
            }
        }

        var endpoint: String {
            switch self {
            case .all, .get:
                return "producers"
            case .beats(let uuid, _):
                return "producers/\(uuid)/beats"
            }
        }

        func asURLRequest() throws -> URLRequest {
            var urlRequest = URLRequest(url: try ProducersClient.shared.apiUrl(endpoint: endpoint).asURL())
            urlRequest.httpMethod = method.rawValue
            switch self {
            case .all:
                urlRequest = try URLEncoding.default.encode(urlRequest, with: [
                    "all": ""
                    ])
            case .get(let page):
                urlRequest = try URLEncoding.default.encode(urlRequest, with: [
                    "page": page,
                    "limit": Router.limit
                ])
            case .beats(_, let page):
                urlRequest = try URLEncoding.default.encode(urlRequest, with: [
                    "page": page,
                    "limit": Router.limit
                ])
            }
            return urlRequest
        }
    }

    func all(success: @escaping (_ response: [Producer]?) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequest(Router.all, success: { (json) in
            let producers = json["data"].array?.map({ ProducersClient.producer(fromJson: $0) })
            success(producers)
        }, failure: failure)
    }

    func get(page: Int, success: @escaping (_ response: [Producer]?, _ total: Int?) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequest(Router.get(page: page), success: { (json) in
            let producers = json["data"].array?.map({ ProducersClient.producer(fromJson: $0) })
            let total = json["meta"]["total"].int
            success(producers, total)
        }, failure: failure)
    }
    
    @discardableResult
    func beats(uuid: String, page: Int, success: @escaping (_ response: [Beat]?, _ total: Int?, _ limit: Int) -> Void, failure: @escaping (_ error: NSError) -> Void) -> DataRequest {
        return defaultRequest(Router.beats(uuid: uuid, page: page), success: { (json) in
            let beats = json["data"].array?.map({ BeatsClient.beat(fromJson: $0) })
            let total = json["meta"]["total"].int
            success(beats, total, Router.limit)
        }, failure: failure)
    }

    static func producer(fromJson json: JSON) -> Producer {
        var producer = Producer()
        producer.uuid = json["uuid"].string
        producer.name = json["name"].string
        producer.username = json["username"].string
        producer.profilePicture = json["profile_picture"].url
        producer.averageRating = json["average_rating"].double
        producer.followersCount = json["follower_count"].int

        return producer
    }
}
