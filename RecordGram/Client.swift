//
//  Client.swift
//  RecordGram
//
//  Created by Hugo Prione on 15/09/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import JWT

class Client {
    // Ensure requests always have necessary headers, and appends jwt when available
    lazy var sessionManager: SessionManager = {
        var defaultHeaders = Alamofire.SessionManager.defaultHTTPHeaders
        defaultHeaders["Accept"] = "application/json"

        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = defaultHeaders

        let sessionManager = Alamofire.SessionManager(configuration: configuration)

        sessionManager.adapter = JWTRequestAdapter()

        return sessionManager
    }()

    func apiUrl(endpoint: String) -> String {
        #if STAGING
            return "https://api.staging.recordgram.com/v2/" + endpoint
        #else
            return "https://api.recordgram.com/v2/" + endpoint
        #endif
    }

    func logError(error: NSError) {
        print("Error \(error), \(error.localizedDescription)")
    }

    // TODO: Might want to move this to be it's own thing
    func decodedJWT() -> ClaimSet {
        if let jwt = UserDefaults.standard.string(forKey: kJWTKey) {
            do {
                return try JWT.decode(jwt, algorithm: .none, verify: false)
            } catch {
                print("Failed to decode JWT: \(error)")
            }
        }
        return ClaimSet()
    }
    
    @discardableResult
    func defaultRequest(_ urlRequest: URLRequestConvertible, success: @escaping (_ response: JSON) -> Void, failure: @escaping (_ error: NSError) -> Void) -> DataRequest {
        return sessionManager.request(urlRequest)
                .responseJSON { response in
                    switch response.result {
                    case .success(let result):
                        let json = JSON(result)

                        let statusCode = response.response?.statusCode ?? 0
                        switch statusCode {
                        case 200..<300:
                            success(json)
                        default:
                            var errorMessage = ""
                            if let errors = json["errors"].dictionaryObject {
                                for (_, errors) in errors {
                                    if let errors = errors as? [String] {
                                        for error in errors {
                                            errorMessage.append(error + "\n")
                                        }
                                    }
                                }
                            }
                            if errorMessage.isEmpty {
                                errorMessage = json["message"].stringValue
                            }
                            failure(NSError(domain: "RecordGram", code: statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
                        }
                    case .failure(let error):
                        self.defaultError(error: error, failure: failure)
                    }
                }
    }

    func defaultRequestNoResponse(_ urlRequest: URLRequestConvertible, success: @escaping () -> Void, failure: @escaping (_ error: NSError) -> Void) {
        sessionManager.request(urlRequest)
                .validate()
                .response(completionHandler: { response in
                    if let error = response.error {
                        self.defaultError(error: error, failure: failure)
                        return
                    }

                    success()
                })
    }

    // TODO: implement 2017-11-28 (table of errors (?))
    func defaultError(error: Error, failure: @escaping (_ error: NSError) -> Void) {
        guard let afError = error as? AFError else {
            failure(NSError(domain: "RecordGram", code: 999, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription]))
            return
        }
        failure(NSError(domain: "RecordGram", code: afError.responseCode ?? 0, userInfo: [NSLocalizedDescriptionKey: afError.errorDescription ?? ""]))
    }

    func uuid() -> String {
        if let uuid = decodedJWT()["sub"] {
            return uuid as! String
        }
        return ""
    }
}
