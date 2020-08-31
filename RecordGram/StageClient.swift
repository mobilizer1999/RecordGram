//
//  StageClient.swift
//  RecordGram
//
//  Created by Nicolas Gonzalez on 12/2/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class StageClient: Client {
    static let shared = StageClient()
    
    enum Router: URLRequestConvertible {
        case get(groups: String, page: Int)
        var method: HTTPMethod {
            switch self {
            case .get:
                return .get
            }
        }
        static let limit = 9
        
        var endpoint: String {
            switch self {
            case .get:
                return "stage"
            }
        }
        
        func asURLRequest() throws -> URLRequest {
            var urlRequest = URLRequest(url: try StageClient.shared.apiUrl(endpoint: endpoint).asURL())
            urlRequest.httpMethod = method.rawValue
            switch self {
            case .get(let groups, let page):
                urlRequest = try URLEncoding.default.encode(urlRequest, with: [
                    "groups": groups,
                    "page": page,
                    "limit": Router.limit
                    ])
            }
            return urlRequest
        }
    }
    
    @discardableResult
    func get(groups: String, page: Int, success: @escaping (_ feed: [HomeFeed]?, _ total: Int?, _ limit: Int) -> Void, failure: @escaping (_ error: NSError) -> Void) -> DataRequest {
        return defaultRequest(Router.get(groups: groups, page: page), success: { (json) in
            let feed = json["data"].array?.map({ StageClient.feed(fromJson: $0) })
            let total = json["meta"]["total"].int
            success(feed, total, Router.limit)
        }, failure: failure)
    }
    
    static func feed(fromJson json: JSON) -> HomeFeed {
        var feed = HomeFeed()
        
        feed.uuid = json["uuid"].string
        feed.title = json["title"].string
        feed.type = json["type"].string
        feed.url = json["url"].string
        feed.gif = json["gif"].string
        feed.thumbnail = json["thumbnail"].string
        feed.user = UserClient.user(fromJson: json["user"])
        feed.producer = ProducersClient.producer(fromJson: json["producer"])

        return feed
    }
}
