//
// Created by Nicolas Gonzalez on 11/17/17.
// Copyright (c) 2017 Meridian Inc. All rights reserved.
//

import Alamofire
import SwiftyJSON

class SearchClient: Client {

    static let shared = SearchClient()

    enum Router: URLRequestConvertible {
        case search(query: String, groups: String, page: Int)
        case findPeople(parameters: Parameters)
        
        static let limit = 6

        func asURLRequest() throws -> URLRequest {
            
            let parameters: Parameters = {
                switch self {
                case let .search(query, groups, page):
                    return [
                        "q": query,
                        "groups": groups,
                        "page": page,
                        "limit": Router.limit
                    ]
                case let .findPeople(parameters):
                    return parameters
                }
            }()
            return try URLEncoding.default.encode(URLRequest(url: try SearchClient.shared.apiUrl(endpoint: "search").asURL()), with: parameters)
        }
    }

    @discardableResult
    func get(query: String, groups: String, page: Int, success: @escaping (_ response: JSON, _ total: Int?, _ limit: Int) -> Void, failure: @escaping (_ error: NSError) -> Void) -> DataRequest {
        return defaultRequest(Router.search(query: query, groups: groups, page: page), success: { (json) in
            let total = json["meta"]["total"].int
            
            success(json, total, Router.limit)
        }, failure: failure)
    }
    
    func findPeople(parameters: Parameters, success: @escaping (_ response: JSON) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequest(Router.findPeople(parameters: parameters), success: success, failure: failure)
    }
}
