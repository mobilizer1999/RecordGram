//
//  VideosClient.swift
//  RecordGram
//
//  Created by Hugo Prione on 15/09/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import CoreLocation

class VideosClient: Client {
    static let shared = VideosClient()

    private lazy var videos: [String: Video] = [:]

    enum Router: URLRequestConvertible {
        case fetch(uuid: String)
        case likes(uuid: String)
        case like(uuid: String)
        case unlike(uuid: String)
        case comments(uuid: String)
        case comment(comment: Comment)
        case deleteComment(comment: Comment)
        case update(video: Video)
        case delete(uuid: String)
        case howTo()
        case view(uuid: String)

        static let limit = 8

        var method: HTTPMethod {
            switch self {
            case .fetch, .likes, .comments, .howTo:
                return .get
            case .like, .comment, .view:
                return .post
            case .unlike, .delete, .deleteComment:
                return .delete
            case .update:
                return .put
            }
        }
        
        var endpoint: String {
            switch self {
            case .fetch(let uuid):
                return "videos/\(uuid)"
            case .update(let video):
                return "videos/\(video.uuid ?? "")"
            case .likes(let uuid), .like(let uuid), .unlike(let uuid):
                return "videos/\(uuid)/likes"
            case .comments(let uuid):
                return "videos/\(uuid)/comments"
            case .comment(let comment):
                return "videos/\(comment.media?.uuid ?? "")/comments"
            case .deleteComment(let comment):
                return "videos/\(comment.media?.uuid ?? "")/comments/\(comment.uuid ?? "")"
            case .delete(let uuid):
                return "videos/\(uuid)"
            case .howTo():
                return "how-to-videos"
            case .view(let uuid):
                return "videos/\(uuid)/track-view"
            }
        }
        
        func asURLRequest() throws -> URLRequest {
            var urlRequest = URLRequest(url: try VideosClient.shared.apiUrl(endpoint: endpoint).asURL())
            urlRequest.httpMethod = method.rawValue
            
            switch self {
            case .update(let video):
                var parameters = Parameters()
                parameters["title"] = video.name
                parameters["description"] = video.description
                parameters["public"] = video.isPublic
                
                urlRequest = try URLEncoding.default.encode(urlRequest, with: parameters)
            case .comment(let comment):
                var parameters = Parameters()
                parameters["body"] = comment.body
                
                urlRequest = try URLEncoding.default.encode(urlRequest, with: parameters)
            default:
                break
            }
            
            return urlRequest
        }
    }

    func get(uuid: String, success: @escaping (_ response: Video) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        if let video = videos[uuid] {
            success(video)
            return
        }

        defaultRequest(Router.fetch(uuid: uuid), success: { json in
            let video = VideosClient.video(fromJson: json["data"])

            self.videos[uuid] = video
            
            success(video)
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
    
    func upload(video: Video, success: @escaping (_ uuid: String?) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        let url = apiUrl(endpoint: "videos")
        guard let videoUrl = video.url else {
            return
        }
        
        sessionManager.upload(multipartFormData: { multipartFormData in
            multipartFormData.append((video.name ?? "").data(using: .utf8)!, withName: "title")
            multipartFormData.append((video.description ?? "").data(using: .utf8)!, withName: "description")
            multipartFormData.append(String(describing: video.coordinate?.latitude ?? 0).data(using: .utf8)!, withName: "lat")
            multipartFormData.append(String(describing: video.coordinate?.longitude ?? 0).data(using: .utf8)!, withName: "long")
            multipartFormData.append(String(describing: (video.isPublic == true ? 1 : 0)).data(using: .utf8)!, withName: "public")
            multipartFormData.append((video.beat?.uuid ?? "").data(using: .utf8)!, withName: "beat")
            multipartFormData.append((video.contest?.uuid ?? "").data(using: .utf8)!, withName: "contest")
            multipartFormData.append(videoUrl, withName: "file", fileName: "video.mp4", mimeType: "video/mp4")
        }, to: url, encodingCompletion: { encodingResult in
            switch encodingResult {
            case .success(let upload, _, _):
                upload.responseJSON { response in
                    guard let value = response.result.value else {
                        success(nil)
                        return
                    }
                    let json = JSON(value)
                    let uuid = json["data"]["uuid"].string
                    
                    success(uuid)
                }
            case .failure(let error):
                self.defaultError(error: error, failure: failure)
            }
        })
    }
    
    func update(video: Video, success: @escaping () -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequest(Router.update(video: video), success: { (_) in
            success()
        }, failure: failure)
    }
    
    func delete(uuid: String, success: @escaping () -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequest(Router.delete(uuid: uuid), success: { (_) in
            success()
        }, failure: failure)
    }
    
    func comments(uuid: String, success: @escaping (_ comments: [Comment]?) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequest(Router.comments(uuid: uuid), success: { (json) in
            // FIXME: 2017-12-01 use media from comment
            let video = Video()
            video.uuid = uuid
            
            let comments = json["data"].array?.map({ (json) -> Comment in
                return VideosClient.comment(fromJson: json, media: video)
            })
            success(comments)
        }, failure: failure)
    }
    
    func comment(comment: Comment, success: @escaping (_ comment: Comment?) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequest(Router.comment(comment: comment), success: { (json) in
            // FIXME: 2017-12-01 use media from comment
            guard let media = comment.media else {
                fatalError()
            }
            let comment = VideosClient.comment(fromJson: json["data"], media: media)
            
            success(comment)
        }, failure: failure)
    }
    
    func delete(comment: Comment, success: @escaping () -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequest(Router.deleteComment(comment: comment), success: { (_) in
            success()
        }, failure: failure)
    }

    func howTo(success: @escaping (_ feed: [HowToVideo]?) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequest(Router.howTo(), success: { json in
            let videos = json["data"].array?.map({ VideosClient.howToVideo(fromJson: $0) })
            success(videos)
        }, failure: failure)
    }

    func view(_ uuid: String, success: @escaping () -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequestNoResponse(Router.view(uuid: uuid), success: success, failure: failure)
    }
    
    // TODO: refactor 2017-12-01 (move)
    static func comment(fromJson json: JSON, media: Media) -> Comment {
        let uuid = json["uuid"].string
        let body = json["body"].string?.decodeEmoji
        let user = UserClient.user(fromJson: json["user"])
        
        return Comment(uuid: uuid, body: body, media: media, user: user)
    }

    static func video(fromJson json: JSON) -> Video {
        let video = Video()
        video.name = json["title"].string
        video.uuid = json["uuid"].string
        video.url = json["url"].url
        video.gif = json["gif"].url
        video.thumb = json["thumbnail"].url
        video.description = json["description"].string?.decodeEmoji
        video.beat = BeatsClient.beat(fromJson: json["beat"])
        video.isPublic = json["public"].bool
        let latitude = Double(json["coordinates"]["latitude"].stringValue) ?? 0
        let longitude = Double(json["coordinates"]["longitude"].stringValue) ?? 0
        video.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        video.user = UserClient.user(fromJson: json["user"])
        video.isLiked = json["liked"].bool
        video.views = json["view_count"].int
        video.comments = json["comments"].int

        return video
    }

    static func howToVideo(fromJson json: JSON) -> HowToVideo {
        var howToVideo = HowToVideo()

        howToVideo.title = json["title"].string
        howToVideo.path = URL(string: "https://s3.amazonaws.com/recordgram/public/" + json["path"].stringValue)
        howToVideo.thumb = URL(string: "https://www.recordgram.com/public/" + json["thumb"].stringValue)

        return howToVideo
    }
}
