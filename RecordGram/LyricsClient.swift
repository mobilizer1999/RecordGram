//
//  LyricsClient.swift
//  RecordGram
//
//  Created by Hugo Prione on 15/09/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class LyricsClient: Client {
    static let shared = LyricsClient()
    
    private lazy var lyrics = [String: Lyric]()
    
    enum Router: URLRequestConvertible {
        case all(page: Int)
        case get(uuid: String)
        case create(lyric: Lyric)
        case update(lyric: Lyric)
        case delete(uuid: String)
        
        var method: HTTPMethod {
            switch self {
            case .get, .all:
                return .get
            case .create:
                return .post
            case .delete:
                return .delete
            case .update:
                return .put
            }
        }
        
        var endpoint: String {
            switch self {
            case .get(let uuid), .delete(let uuid):
                return "lyrics/\(uuid)"
            case .update(let lyric):
                return "lyrics/\(lyric.uuid ?? "")"
            case .all(_): // TODO: implement 2017-12-05 (pagination)
                return "lyrics"
            case .create:
                return "lyrics"
            }
        }
        
        func asURLRequest() throws -> URLRequest {
            var urlRequest = URLRequest(url: try LyricsClient.shared.apiUrl(endpoint: endpoint).asURL())
            urlRequest.httpMethod = method.rawValue
            
            switch self {
            case .update(let lyric), .create(let lyric):
                var parameters = Parameters()
                parameters["title"] = lyric.title ?? ""
                parameters["body"] = lyric.body ?? ""
                
                urlRequest = try URLEncoding.default.encode(urlRequest, with: parameters)
            default:
                break
            }
            
            return urlRequest
        }
    }
    
    func get(uuid: String, success: @escaping (_ lyric: Lyric) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        if let lyric = lyrics[uuid] {
            success(lyric)
            return
        }
        
        defaultRequest(Router.get(uuid: uuid), success: { (json) in
            let lyric = LyricsClient.lyric(fromJson: json["data"])
            
            self.lyrics[uuid] = lyric
            
            success(lyric)
        }, failure: failure)
    }
    
    func all(page: Int, success: @escaping (_ lyrics: [Lyric]?) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequest(Router.all(page: page), success: { (json) in
            let lyrics = json["data"].array?.map({ (json) -> Lyric in
                return LyricsClient.lyric(fromJson: json["data"])
            })
            success(lyrics)
        }, failure: failure)
    }
    
    func create(lyric: Lyric, success: @escaping (_ lyric: Lyric) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequest(Router.create(lyric: lyric), success: { (json) in
            let lyric = LyricsClient.lyric(fromJson: json["data"])
            success(lyric)
        }, failure: failure)
    }
    
    func update(lyric: Lyric, success: @escaping (_ lyric: Lyric) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequest(Router.update(lyric: lyric), success: { (json) in
            let lyric = LyricsClient.lyric(fromJson: json["data"])
            success(lyric)
        }, failure: failure)
    }
    
    func delete(uuid: String, success: @escaping () -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequest(Router.delete(uuid: uuid), success: { (_) in
            success()
        }, failure: failure)
    }
    
    static func lyric(fromJson json: JSON) -> Lyric {
        let uuid = json["uuid"].string
        let title = json["title"].string
        let body = json["body"].string?.decodeEmoji
        
        return Lyric(uuid: uuid, title: title, body: body)
    }
}
