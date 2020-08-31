//
//  InviteClient.swift
//  RecordGram
//
//  Created by Mauro Taroco on 5/12/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class InviteClient: Client {
    static let shared = InviteClient()

    enum Router: URLRequestConvertible {
        case send(parameters: Parameters)
        
        var method: HTTPMethod {
            return .post
        }
        
        var endpoint: String {
            return "invite"
        }
        
        func asURLRequest() throws -> URLRequest {
            var urlRequest = URLRequest(url: try UserClient.shared.apiUrl(endpoint: endpoint).asURL())
            urlRequest.httpMethod = method.rawValue
            
            switch self {
            case .send(let parameters):
                urlRequest = try JSONEncoding.default.encode(urlRequest, with: parameters)
            }

            return urlRequest
        }
    }

    func sendInvite(parameters: Parameters, success: @escaping (Bool) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequest(Router.send(parameters: parameters), success: { json in
            print(json)
            success(true)
//            if let status = json["status"].bool {
//                success(status)
//            } else {
//                success(false)
//            }
        }, failure: failure)
    }

}
