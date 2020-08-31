//
//  JWTRequestAdapter.swift
//  RecordGram
//
//  Created by Nicolas Gonzalez on 11/15/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import Alamofire

class JWTRequestAdapter: RequestAdapter {
    func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
        var urlRequest = urlRequest
        if let jwt = UserDefaults.standard.string(forKey: kJWTKey) {
            urlRequest.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
//            print("Bearer \(jwt)")
        }
        return urlRequest
    }
}
