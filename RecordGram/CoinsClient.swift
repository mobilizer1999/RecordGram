//
//  CoinsClient.swift
//  RecordGram
//
//  Created by Nicolas Gonzalez on 3/6/18.
//  Copyright © 2018 Meridian Inc. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class CoinsClient: Client {
    static let shared = CoinsClient()

    enum Router: URLRequestConvertible {
        case validate(receipt: String)
        var method: HTTPMethod {
            switch self {
            case .validate:
                return .post
            }
        }

        var endpoint: String {
            switch self {
            case .validate:
                return "credits/purchase"
            }
        }

        func asURLRequest() throws -> URLRequest {
            var urlRequest = URLRequest(url: try CoinsClient.shared.apiUrl(endpoint: endpoint).asURL())
            urlRequest.httpMethod = method.rawValue
            switch self {
            case .validate(let receipt):
                var parameters = Parameters()
                parameters["receipt"] = receipt
                parameters["type"] = "ios"

                urlRequest = try URLEncoding.default.encode(urlRequest, with: parameters)
            }
            return urlRequest
        }
    }

    func validatePurchase(with receipt: String, success: @escaping () -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequest(Router.validate(receipt: receipt), success: { json in
            success()
        }, failure: failure)
    }
}
