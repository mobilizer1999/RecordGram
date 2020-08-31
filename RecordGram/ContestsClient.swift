//
//  ContestsClient.swift
//  RecordGram
//
//  Created by Hugo Prione on 15/09/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class ContestsClient: Client {
    static let shared = ContestsClient()
    
    enum Router: URLRequestConvertible {
        case all
        case get(uuid: String)
        case allVideos(uuid: String)
        case allSongs(uuid: String)
        
        var method: HTTPMethod {
            switch self {
            case .all, .get, .allVideos, .allSongs:
                return .get
            }
        }
        
        var endpoint: String {
            switch self {
            case .all:
                return "contests?filter=active"
            case .get(let uuid):
                return "contests/\(uuid)/"
            case .allVideos(let uuid):
                return "contests/\(uuid)/videos"
            case .allSongs(let uuid):
                return "contests/\(uuid)/songs"
            }
        }
        
        func asURLRequest() throws -> URLRequest {
            var urlRequest = URLRequest(url: try ContestsClient.shared.apiUrl(endpoint: endpoint).asURL())
            urlRequest.httpMethod = method.rawValue
            
            return urlRequest
        }
    }
    
    func all(success: @escaping (_ response: [Contest]?) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequest(Router.all, success: { (json) in
            let contests = json["data"].array?.map({ ContestsClient.contest(fromJson: $0) })
            
            success(contests)
        }, failure: failure)
    }
    
    func allVideos(uuid: String, success: @escaping (_ response: [Video]?) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequest(Router.allVideos(uuid: uuid), success: { (json) in
            let videos = json["data"].array?.map({ VideosClient.video(fromJson: $0) })
            
            success(videos)
        }, failure: failure)
    }
    
    func allSongs(uuid: String, success: @escaping (_ response: [Song]?) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequest(Router.allSongs(uuid: uuid), success: { (json) in
            let songs = json["data"].array?.map({ SongsClient.song(fromJson: $0) })
            
            success(songs)
        }, failure: failure)
    }

    func get(uuid: String, success: @escaping (_ response: Contest?) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequest(Router.get(uuid: uuid), success: { (json) in
            let contest = ContestsClient.contest(fromJson: json)
            
            success(contest)
        }, failure: failure)
    }
    
    static func contest(fromJson json: JSON) -> Contest {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .none
        dateFormatter.dateStyle = .none
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var contest = Contest()
        contest.uuid = json["uuid"].string
        contest.title = json["title"].string
        contest.hashtag = json["hashtag"].string
        contest.thumbnail = json["thumbnail"].url
        contest.setContestType(json["type"].stringValue)

        if let rawDate = json["start_date"].string {
            contest.startDate = dateFormatter.date(from: rawDate)
        }
        if let rawDate = json["end_date"].string {
            contest.endDate = dateFormatter.date(from: rawDate)
        }
        
        return contest
    }
}
