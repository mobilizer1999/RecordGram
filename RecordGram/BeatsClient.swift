//
//  BeatsClient.swift
//  RecordGram
//
//  Created by Hugo Prione on 15/09/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class BeatsClient: Client {
    static let shared = BeatsClient()

    var beats: [String: Beat] = [:]

    enum Router: URLRequestConvertible {
        case all
        case one(uuid: String)
        case get(genre: String, page: Int)
        case hot(page: Int)
        case likes(uuid: String)
        case like(uuid: String)
        case unlike(uuid: String)
        case trackDownload(uuid: String)
        case purchase(uuid: String)
        case view(uuid: String)

        static let limit = 8

        var method: HTTPMethod {
            switch self {
            case .get, .one, .all, .likes, .hot:
                return .get
            case .like, .trackDownload, .purchase, .view:
                return .post
            case .unlike:
                return .delete
            }
        }

        var endpoint: String {
            switch self {
            case .one(let uuid):
                return "beats/\(uuid)"
            case .all, .get(_, _), .hot:
                return "beats"
            case .likes(let uuid), .like(let uuid), .unlike(let uuid):
                return "beats/\(uuid)/likes"
            case .trackDownload(let uuid):
                return "beats/\(uuid)/track-download"
            case .purchase(let uuid):
                return "beats/\(uuid)/purchase"
            case .view(let uuid):
                return "beats/\(uuid)/track-view"
            }
        }

        func asURLRequest() throws -> URLRequest {
            var urlRequest = URLRequest(url: try HomeFeedClient.shared.apiUrl(endpoint: endpoint).asURL())
            urlRequest.httpMethod = method.rawValue

            switch self {
            case .get(let genre, let page):
                var parameters: [String: Any] = [
                    "page": page,
                    "limit": Router.limit
                ]
                if genre != "" {
                    parameters["genre"] = genre
                }
                urlRequest = try URLEncoding.default.encode(urlRequest, with: parameters)
            case .hot(let page):
                let parameters: [String: Any] = [
                    "page": page,
                    "limit": Router.limit,
                    "sort": "hot"
                ]
                urlRequest = try URLEncoding.default.encode(urlRequest, with: parameters)
            default:
                break
            }

            return urlRequest
        }
    }

    func get(uuid: String, success: @escaping (_ response: Beat) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        if let beat = beats[uuid] {
            success(beat)
        } else {
            defaultRequest(Router.one(uuid: uuid), success: { response in
                let beat = BeatsClient.beat(fromJson: response["data"])
                self.beats[uuid] = beat
                success(beat)
            }, failure: failure)
        }
    }

    @discardableResult
    func get(page: Int, success: @escaping (_ beats: [Beat]?, _ total: Int?, _ limit: Int) -> Void, failure: @escaping (_ error: NSError) -> Void) -> DataRequest {
        return defaultRequest(Router.hot(page: page), success: { (json) in
            let beats = json["data"].array?.map({ BeatsClient.beat(fromJson: $0) })
            let total = json["meta"]["total"].int
            success(beats, total, Router.limit)
        }, failure: failure)
    }

    @discardableResult
    func get(genre: String, page: Int, success: @escaping (_ beats: [Beat]?, _ total: Int?, _ limit: Int) -> Void, failure: @escaping (_ error: NSError) -> Void) -> DataRequest {
        return defaultRequest(Router.get(genre: genre, page: page), success: { (json) in
            let beats = json["data"].array?.map({ BeatsClient.beat(fromJson: $0) })
            let total = json["meta"]["total"].int
            success(beats, total, Router.limit)
        }, failure: failure)
    }

    func all(success: @escaping (_ beats: [Beat]?) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequest(Router.all, success: { (json) in
            let beats = json["data"].array?.map({ BeatsClient.beat(fromJson: $0) })
            success(beats)
        }, failure: failure)
    }

    func likes(uuid: String, success: @escaping (_ response: [User]?) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequest(Router.likes(uuid: uuid), success: { (json) in
            let users = json["data"].array?.map({ (json) -> User in
                return UserClient.user(fromJson: json)
            })
            success(users)
        }, failure: failure)
    }

    func like(uuid: String, success: @escaping () -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequestNoResponse(Router.like(uuid: uuid), success: success, failure: failure)
    }

    func unlike(uuid: String, success: @escaping () -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequest(Router.unlike(uuid: uuid), success: { (_) in
            success()
        }, failure: failure)
    }

    func download(url: URL, destinationUrl: URL, progress: @escaping (_ value: Double) -> Void, success: @escaping (_ url: URL) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            return (destinationUrl, [.removePreviousFile, .createIntermediateDirectories])
        }

        Alamofire.download(url, to: destination)
                .downloadProgress(queue: DispatchQueue.main) { (p) in
                    progress(p.fractionCompleted)
                }
                .responseData(queue: DispatchQueue.main) { (response) in
                    switch response.result {
                    case .success:
                        success(destinationUrl)
                    case .failure(let error):
                        self.defaultError(error: error, failure: failure)
                    }
                }
    }

    func trackDownload(uuid: String, success: @escaping () -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequest(Router.trackDownload(uuid: uuid), success: { _ in
            success();
        }, failure: failure)
    }

    func purchase(uuid: String, success: @escaping () -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequest(Router.purchase(uuid: uuid), success: { _ in
            success();
        }, failure: failure)
    }

    func view(_ uuid: String, success: @escaping () -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequestNoResponse(Router.view(uuid: uuid), success: success, failure: failure)
    }

    static func beat(fromJson json: JSON) -> Beat {
        let beat = Beat()
        beat.uuid = json["uuid"].string
        beat.name = json["name"].string
        beat.description = json["description"].string
        beat.url = json["url"].url
        beat.price = json["price"].int
        beat.image = json["image"].url
        beat.producer = ProducersClient.producer(fromJson: json["producer"])
        beat.genre = GenresClient.genre(fromJson: json["genre"])
        beat.purchased = json["purchased"].bool
        beat.isLiked = json["liked"].bool
        beat.views = json["view_count"].int

        return beat
    }
}
