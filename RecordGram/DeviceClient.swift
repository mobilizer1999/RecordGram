//
//  DeviceClient.swift
//  RecordGram
//
//  Created by Nicolas Gonzalez on 4/1/18.
//  Copyright © 2018 Meridian Inc. All rights reserved.
//

import Foundation
import Alamofire

class DeviceClient: Client {
    static let shared = DeviceClient()

    enum Router: URLRequestConvertible {
        case attach
        case detach
        var method: HTTPMethod {
            switch self {
            case .attach, .detach:
                return .post
            }
        }

        var endpoint: String {
            switch self {
            case .attach:
                return "devices/attach"
            case .detach:
                return "devices/detach"
            }
        }

        func asURLRequest() throws -> URLRequest {
            var urlRequest = URLRequest(url: try CoinsClient.shared.apiUrl(endpoint: endpoint).asURL())
            urlRequest.httpMethod = method.rawValue

            var parameters = Parameters()

            switch self {
            case .attach:
                parameters = [
                    "device_token": (UIApplication.shared.delegate as! AppDelegate).deviceToken,
                    "device_type": "iOS",
                    "device_name": UIDevice.current.name,
                    "app_version": Bundle.main.infoDictionary!["CFBundleShortVersionString"]!,
                    "os_version": UIDevice.current.systemVersion,
                    "udid": UIDevice.current.identifierForVendor!.uuidString
                ]
            case .detach:
                parameters = [
                    "device_token": (UIApplication.shared.delegate as! AppDelegate).deviceToken,
                    "device_type": "iOS",
                ]
            }

            urlRequest = try URLEncoding.default.encode(urlRequest, with: parameters)
            return urlRequest
        }
    }

    func attach() {
        defaultRequestNoResponse(Router.attach, success: {}, failure: { error in })
    }

    func detach() {
        defaultRequestNoResponse(Router.detach, success: {}, failure: { error in })
    }
}
