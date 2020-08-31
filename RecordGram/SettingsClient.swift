//
//  SettingClient.swift
//  RecordGram
//
//  Created by Hugo Prione on 15/09/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class SettingsClient: Client {
    
    static let shared = SettingsClient()
    
    enum Router: URLRequestConvertible {
        case terms()
        case privacy()
        
        var method: HTTPMethod {
            switch self {
            case .terms, .privacy:
                return .get
            }
        }
        
        var endpoint: String {
            switch self {
            case .terms:
                return "settings/terms"
            case .privacy:
                return "settings/privacy"
            }
        }
        
        func asURLRequest() throws -> URLRequest {
            var urlRequest = URLRequest(url: try HomeFeedClient.shared.apiUrl(endpoint: endpoint).asURL())
            urlRequest.httpMethod = method.rawValue
            
            return urlRequest
        }
    }
    
    func terms(success: @escaping (_ terms: String?) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequest(Router.terms(), success: { (json) in
            success(json["data"].string)
        }, failure: failure)
    }

    func privacy(success: @escaping (_ privacy: String?) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequest(Router.privacy(), success: { (json) in
            success(json["data"].string)
        }, failure: failure)
    }
}
