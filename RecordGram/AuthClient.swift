//
//  AuthClient.swift
//  RecordGram
//
//  Created by Hugo Prione on 15/09/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import JWT

class AuthClient: Client {
    // TODO: refactor (use new client structure)
    func login(authCode: String, success:@escaping (_ decodedJWT: ClaimSet) -> Void, failure:@escaping (_ error: NSError) -> Void) {
        let url = apiUrl(endpoint: "auth/login")
        let parameters = ["code": authCode]
        
        Alamofire.request(url, method: .post, parameters: parameters).validate().responseJSON { (response) in
            switch response.result {
                
            case .success(let result):
                let json = JSON(result)
                let defaults = UserDefaults.standard
                defaults.set(json["data"]["jwt"].string, forKey: kJWTKey)

                DeviceClient.shared.attach()

                success(self.decodedJWT())
            case .failure(let error):
                guard let afError = error as? AFError else {
                    failure(NSError(domain: "RecordGram", code: 999, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription]))
                    return
                }
                
                failure(NSError(domain: "RecordGram", code: afError.responseCode ?? 0, userInfo: [NSLocalizedDescriptionKey: afError.errorDescription ?? ""]))
            }
        }
    }
}
