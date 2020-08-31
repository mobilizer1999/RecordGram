//
//  SongsClient.swift
//  RecordGram
//
//  Created by Hugo Prione on 15/09/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import CoreLocation

class SongsClient: Client {
    static let shared = SongsClient()

    private lazy var songs = [String: Song]()

    enum Router: URLRequestConvertible {
        case all(page: Int)
        case get(uuid: String)
        case likes(uuid: String)
        case update(song: Song)
        case delete(uuid: String)
        case like(uuid: String)
        case unlike(uuid: String)
        case comments(uuid: String)
        case comment(comment: Comment)
        case deleteComment(comment: Comment)
        case view(uuid: String)

        var method: HTTPMethod {
            switch self {
            case .get, .likes, .comments, .all:
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
            case .get(let uuid), .delete(let uuid):
                return "songs/\(uuid)"
            case .update(let song):
                return "songs/\(song.uuid ?? "")"
            case .all(_):
                return "songs"
            case .likes(let uuid), .like(let uuid), .unlike(let uuid):
                return "songs/\(uuid)/likes"
            case .comments(let uuid):
                return "songs/\(uuid)/comments"
            case .comment(let comment):
                return "songs/\(comment.media?.uuid ?? "")/comments"
            case .deleteComment(let comment):
                return "songs/\(comment.media?.uuid ?? "")/comments/\(comment.uuid ?? "")"
            case .view(let uuid):
                return "songs/\(uuid)/track-view"
            }
        }

        func asURLRequest() throws -> URLRequest {
            var urlRequest = URLRequest(url: try SongsClient.shared.apiUrl(endpoint: endpoint).asURL())
            urlRequest.httpMethod = method.rawValue

            switch self {
            case .update(let song):
                var parameters = Parameters()
                parameters["title"] = song.name ?? ""
                parameters["public"] = String(describing: (song.isPublic == true ? 1 : 0))
                parameters["description"] = song.description ?? ""

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

    func get(uuid: String, success: @escaping (_ song: Song) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        if let song = songs[uuid] {
            success(song)
            return
        }

        defaultRequest(Router.get(uuid: uuid), success: { (json) in
            let song = SongsClient.song(fromJson: json["data"])

            self.songs[uuid] = song

            success(song)
        }, failure: failure)
    }

    func all(page: Int, success: @escaping (_ songs: [Song]?) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequest(Router.all(page: page), success: { (json) in
            let songs = json["data"].array?.map({ (json) -> Song in
                return SongsClient.song(fromJson: json)
            })
            success(songs)
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

    func update(song: Song, success: @escaping (Song) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequest(Router.update(song: song), success: { json in
            let song = SongsClient.song(fromJson: json["data"])
            success(song)
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

    func upload(song: Song, success: @escaping (_ uuid: String?) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        let url = apiUrl(endpoint: "songs")
        guard let songUrl = song.url else {
            return
        }

        func doUpload(_ thumbnailImageUuid: String? = nil) {
            sessionManager.upload(multipartFormData: { multipartFormData in
                multipartFormData.append((song.name ?? "").data(using: .utf8)!, withName: "title")
                multipartFormData.append((song.description ?? "").data(using: .utf8)!, withName: "description")
                multipartFormData.append((thumbnailImageUuid ?? "").data(using: .utf8)!, withName: "thumb")
                multipartFormData.append(String(describing: song.coordinate?.latitude ?? 0).data(using: .utf8)!, withName: "lat")
                multipartFormData.append(String(describing: song.coordinate?.longitude ?? 0).data(using: .utf8)!, withName: "long")
                multipartFormData.append(String(describing: (song.isPublic == true ? 1 : 0)).data(using: .utf8)!, withName: "public")
                multipartFormData.append((song.beat?.uuid ?? "").data(using: .utf8)!, withName: "beat")
                multipartFormData.append((song.contest?.uuid ?? "").data(using: .utf8)!, withName: "contest")
                multipartFormData.append(songUrl, withName: "file", fileName: "song.m4a", mimeType: "audio/mp4")
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

        if let thumbnailImage = song.thumbnailImage {
            UploadClient.shared.upload(isPublic: true, file: thumbnailImage, success: { uuid in
                doUpload(uuid)
            }, failure: failure)
        } else {
            doUpload()
        }
    }

    func view(_ uuid: String, success: @escaping () -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequestNoResponse(Router.view(uuid: uuid), success: success, failure: failure)
    }

    static func song(fromJson json: JSON) -> Song {
        let song = Song()
        song.uuid = json["uuid"].string
        song.name = json["title"].string
        song.description = json["description"].string?.decodeEmoji
        song.url = json["url"].url
        song.beat = BeatsClient.beat(fromJson: json["beat"])
        song.genre = GenresClient.genre(fromJson: json["genre"])
        song.isPublic = json["public"].bool
        song.gif = json["gif"].url
        song.thumbnail = json["thumbnail"].url
        let latitude = Double(json["coordinates"]["latitude"].stringValue) ?? 0
        let longitude = Double(json["coordinates"]["longitude"].stringValue) ?? 0
        song.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        song.user = UserClient.user(fromJson: json["user"])
        song.isLiked = json["liked"].bool
        song.comments = json["comments"].int
        song.views = json["view_count"].int
        song.contest = ContestsClient.contest(fromJson: json["contest"])

        return song
    }
}
