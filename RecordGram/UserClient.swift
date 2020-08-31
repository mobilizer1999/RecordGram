//
//  UserClient.swift
//  RecordGram
//
//  Created by Hugo Prione on 15/09/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import FBSDKLoginKit
import FBSDKCoreKit
import JWT

class UserClient: Client {

    static let shared = UserClient()

    var user: JSON?
    var users = JSON()
    var profilePicture: UIImage?

    enum Router: URLRequestConvertible {
        case get(uuid: String)
        case update(uuid: String, parameters: Parameters)
        case videos(uuid: String, page: Int, limit: Int)
        case songs(uuid: String, page: Int, limit: Int)
        case following(uuid: String, page: Int)
        case followers(uuid: String, page: Int, query: String)
        case unFollow(uuid: String, following: String)
        case follow(uuid: String, follow: String)
        case usersFollow(parameters: Parameters)
        case findPeople(parameters: Parameters)
        case enableVisible(visible: String)
        case getUserNearby(parameters: Parameters)
        case uploadLocation(parameters: Parameters)
        case blocked(page: Int)
        case block(uuid: String)
        case unblock(uuid: String)
        case likes(uuid: String, page: Int, limit: Int, groups: String)

        case downloadedBeats(uuid: String, page: Int, limit: Int)

        static let limit = 15

        var method: HTTPMethod {
            switch self {
            case .get, .videos, .songs, .following, .followers, .getUserNearby, .blocked, .likes, .downloadedBeats:
                return .get
            case .update:
                return .put
            case .unFollow, .unblock:
                return .delete
            case .follow, .enableVisible, .findPeople, .usersFollow, .uploadLocation, .block:
                return .post
            }
        }

        var endpoint: String {
            switch self {
            case .get(let uuid), .update(let uuid, _):
                return "users/\(uuid)"
            case .videos(let uuid, _, _):
                return "users/\(uuid)/videos"
            case .songs(let uuid, _, _):
                return "users/\(uuid)/songs"
            case .following(let uuid, _), .follow(let uuid, _):
                return "users/\(uuid)/following"
            case .followers(let uuid, _, _):
                return "users/\(uuid)/followers"
            case .unFollow(let uuid, let following):
                return "users/\(uuid)/following/\(following)"
            case .usersFollow:
                return UsersFollowPath
            case .findPeople:
                return FindPeoplePath
            case .enableVisible:
                return UpdateVisibilityPath
            case .getUserNearby:
                return SearchNearbyPath
            case .uploadLocation:
                return UpdateCoordinatePath
            case .blocked, .block:
                return "users/\(UserClient.shared.uuid())/blocked"
            case .unblock(let uuid):
                return "users/\(UserClient.shared.uuid())/blocked/\(uuid)"
            case .likes(let uuid, _, _, _):
                return "users/\(uuid)/likes"
            case .downloadedBeats(let uuid, _, _):
                return "users/\(uuid)/downloaded-beats"
            }
        }

        func asURLRequest() throws -> URLRequest {
            var urlRequest = URLRequest(url: try UserClient.shared.apiUrl(endpoint: endpoint).asURL())
            urlRequest.httpMethod = method.rawValue

            switch self {
            case .update(_, let parameters), .getUserNearby(let parameters), .uploadLocation(let parameters), .usersFollow(let parameters), .findPeople(let parameters):
                urlRequest = try URLEncoding.default.encode(urlRequest, with: parameters)
            case .followers(_, let page, let query):
                urlRequest = try URLEncoding.default.encode(urlRequest, with: [
                    "page": page,
                    "limit": Router.limit,
                    "q": query
                    ])
            case .following(_, let page), .blocked(let page):
                urlRequest = try URLEncoding.default.encode(urlRequest, with: [
                    "page": page,
                    "limit": Router.limit
                ])
            case .follow(_, let follow):
                urlRequest = try URLEncoding.default.encode(urlRequest, with: [
                    "user_id": follow
                ])
            case .songs(_, let page, let limit), .videos(_, let page, let limit), .downloadedBeats(_, let page, let limit):
                urlRequest = try URLEncoding.default.encode(urlRequest, with: [
                    "page": page,
                    "limit": limit
                ])
            case .enableVisible(let visible):
                urlRequest = try URLEncoding.default.encode(urlRequest, with: [
                    "visible_in_nearby": visible
                ])
            case .block(let uuid):
                urlRequest = try URLEncoding.default.encode(urlRequest, with: [
                    "user_id": uuid
                ])
            case .likes(_, let page, let limit, let groups):
                urlRequest = try URLEncoding.default.encode(urlRequest, with: [
                    "page": page,
                    "limit": limit,
                    "groups": groups
                ])
            default:
                break
            }

            return urlRequest
        }
    }

    func invalidateUser() {
        self.user = nil
        self.users.dictionaryObject?.removeValue(forKey: self.uuid())
    }
    
    func invalidateUser(with uuid: String) {
        self.users.dictionaryObject?.removeValue(forKey: uuid)
    }

    func get(_ attribute: String, for uuid: String, success: @escaping (String) -> Void) {
        if let attribute = self.get(attribute, for: uuid) {
            success(attribute)
        } else {
            get(uuid: uuid, success: { response in
                self.get(attribute, for: uuid, success: success)
            }, failure: { error in
                self.logError(error: error)
            })
        }
    }

    func get(_ attribute: String, success: @escaping (String) -> Void) {
        if let attribute = self.get(attribute) {
            success(attribute)
        } else {
            get(success: { response in
                self.user = response["data"]
                self.users[self.uuid()] = self.user!
                self.get(attribute, success: success)
            }, failure: { error in
                self.logError(error: error)
            })
        }
    }

    func get(_ attribute: String) -> String? {
        return get(attribute, for: self.uuid())
    }

    func get(_ attribute: String, for uuid: String) -> String? {
        if users[uuid].exists() {
            let user = self.users[uuid]
            if let attr = user[attribute].string {
                return attr
            } else if let attr = user[attribute].int {
                return String(attr)
            } else {
                return ""
            }
        } else {
            return nil
        }
    }

    func requestSaveResponse(_ urlRequest: URLRequestConvertible, success: @escaping (_ response: Any) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequest(urlRequest, success: { response in
            self.user = response["data"]
            self.users[self.uuid()] = self.user!
            success(response)
        }, failure: failure)
    }

    func requestSaveResponse(_ urlRequest: URLRequestConvertible, success: @escaping (_ response: JSON) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequest(urlRequest, success: { response in
            self.user = response["data"]
            self.users[self.uuid()] = self.user!
            success(response)
        }, failure: failure)
    }

    func get(success: @escaping (_ response: JSON) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequest(Router.get(uuid: uuid()), success: success, failure: failure)
    }

    func update(parameters: Parameters, success: @escaping (_ response: Any) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        requestSaveResponse(Router.update(uuid: uuid(), parameters: parameters), success: success, failure: failure)
    }

    func update(username: String, success: @escaping (_ response: Any) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        update(parameters: ["username": username], success: success, failure: failure)
    }

    func update(bio: String, success: @escaping (_ response: Any) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        update(parameters: ["bio": bio], success: success, failure: failure)
    }

    func update(password: String, success: @escaping (_ response: Any) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        update(parameters: ["password": password], success: success, failure: failure)
    }

    func update(visible: Bool, success: @escaping (_ response: Any) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        update(parameters: ["visible_in_nearby": visible], success: success, failure: failure)
    }

    func update(profilePicture: UIImage, success: @escaping (_ response: Any) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        UploadClient.shared.upload(isPublic: true, file: profilePicture, success: { uuid in
            self.requestSaveResponse(Router.update(uuid: self.uuid(), parameters: ["profile_picture": uuid]), success: success, failure: failure)
        }, failure: failure)
    }

    func videos(for uuid: String = shared.uuid(), page: Int, limit: Int, success: @escaping (_ videos: [Video]?, _ total: Int?) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequest(Router.videos(uuid: uuid, page: page, limit: limit), success: { json in
            let videos = json["data"].array?.map({ json -> Video in
                var json = json
                if self.users[uuid].exists() {
                    json["user"] = self.users[uuid]
                }
                return VideosClient.video(fromJson: json)
            })
            let total = json["meta"]["total"].int
            success(videos, total)
        }, failure: failure)
    }

    func songs(for uuid: String = shared.uuid(), page: Int, limit: Int, success: @escaping (_ songs: [Song]?, _ total: Int?) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequest(Router.songs(uuid: uuid, page: page, limit: limit), success: { json in
            let songs = json["data"].array?.map({ json -> Song in
                var json = json
                if self.users[uuid].exists() {
                    json["user"] = self.users[uuid]
                }
                return SongsClient.song(fromJson: json)
            })
            let total = json["meta"]["total"].int
            success(songs, total)
        }, failure: failure)
    }

    func following(for uuid: String = shared.uuid(), page: Int, success: @escaping (_ following: [User]?, _ total: Int?) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequest(Router.following(uuid: uuid, page: page), success: { json in
            let following = json["data"].array?.map({ json -> User in
                return UserClient.user(fromJson: json)
            })
            let total = json["meta"]["total"].int
            success(following, total)
        }, failure: failure)
    }
    
    @discardableResult
    func followers(for uuid: String = shared.uuid(), query: String = "", page: Int, success: @escaping (_ following: [User]?, _ total: Int?, _ limit: Int) -> Void, failure: @escaping (_ error: NSError) -> Void) -> DataRequest {
        return defaultRequest(Router.followers(uuid: uuid, page: page, query: query), success: { json in
            let followers = json["data"].array?.map({ json -> User in
                return UserClient.user(fromJson: json)
            })
            let total = json["meta"]["total"].int
            success(followers, total, Router.limit)
        }, failure: failure)
    }

    func unFollow(uuid: String, success: @escaping () -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequest(Router.unFollow(uuid: self.uuid(), following: uuid), success: { json in
            self.invalidateUser()
            self.users.dictionaryObject?.removeValue(forKey: uuid)
            success()
        }, failure: failure)
    }

    func follow(uuid: String, success: @escaping () -> Void, failure: @escaping (_ error: NSError) -> Void) {
        sessionManager.request(Router.follow(uuid: self.uuid(), follow: uuid))
                .response { response in
                    let statusCode = response.response?.statusCode ?? 0
                    switch statusCode {
                    case 200..<300:
                        self.invalidateUser()
                        self.users.dictionaryObject?.removeValue(forKey: uuid)
                        success()
                    default:
                        failure(NSError(domain: "RecordGram", code: statusCode, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("Error trying to follow.", comment: "API error")]))
                    }
                }
    }

    func get(uuid: String, success: @escaping (_ response: JSON) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        if users[uuid].exists() {
            success(users[uuid])
        } else {
            defaultRequest(Router.get(uuid: uuid), success: { response in
                self.users[uuid] = response["data"]
                success(response["data"])
            }, failure: failure)
        }
    }

    func enableVisible(visible: Bool, success: @escaping (_ response: Bool) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        update(visible: visible, success: { _ in
            success(true)
        }, failure: failure)
    }

    func findPeople(parameters: Parameters, success: @escaping (_ userFriends: [UserFriend]?) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequest(Router.findPeople(parameters: parameters), success: { json in
            let userFriends = json["data"].array?.map({ json -> UserFriend in
                return UserClient.userFriend(fromJson: json)
            })
            success(userFriends)
        }, failure: failure)
    }


    func getNearbyUser(parameters: Parameters, success: @escaping (_ response: JSON) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequest(Router.getUserNearby(parameters: parameters), success: success, failure: failure)
    }

    func update(latitude: String, longitude: String, success: @escaping (_ response: JSON) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        requestSaveResponse(Router.update(uuid: uuid(), parameters: [kLatitude: latitude, kLongitude: longitude]), success: success, failure: failure)
    }

    func usersFollow(parameters: Parameters, success: @escaping (_ response: JSON) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequest(Router.usersFollow(parameters: parameters), success: success, failure: failure)
    }


    func blocked(page: Int, success: @escaping (_ users: [User]?, _ total: Int?) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequest(Router.blocked(page: page), success: { json in
            let users = json["data"].arrayValue.map({ UserClient.user(fromJson: $0) })
            let total = json["meta"]["total"].int
            return success(users, total)
        }, failure: failure)
    }

    func block(_ uuid: String, success: @escaping () -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequestNoResponse(Router.block(uuid: uuid), success: success, failure: failure)
    }

    func unblock(_ uuid: String, success: @escaping () -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequestNoResponse(Router.unblock(uuid: uuid), success: success, failure: failure)
    }

    func likedVideos(for uuid: String = shared.uuid(), page: Int, limit: Int, success: @escaping (_ videos: [Video]?, _ total: Int?) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequest(Router.likes(uuid: uuid, page: page, limit: limit, groups: "videos"), success: { json in
            let videos = json["data"].array?.map({ json -> Video in
                var json = json
                if self.users[uuid].exists() {
                    json["user"] = self.users[uuid]
                }
                return VideosClient.video(fromJson: json)
            })
            let total = json["meta"]["total"].int
            success(videos, total)
        }, failure: failure)
    }

    func likedSongs(for uuid: String = shared.uuid(), page: Int, limit: Int, success: @escaping (_ songs: [Song]?, _ total: Int?) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequest(Router.likes(uuid: uuid, page: page, limit: limit, groups: "songs"), success: { json in
            let songs = json["data"].array?.map({ json -> Song in
                var json = json
                if self.users[uuid].exists() {
                    json["user"] = self.users[uuid]
                }
                return SongsClient.song(fromJson: json)
            })
            let total = json["meta"]["total"].int
            success(songs, total)
        }, failure: failure)
    }

    @discardableResult
    func likedBeats(for uuid: String = shared.uuid(), page: Int, limit: Int, success: @escaping (_ beats: [Beat]?, _ total: Int?) -> Void, failure: @escaping (_ error: NSError) -> Void) -> DataRequest {
        return defaultRequest(Router.likes(uuid: uuid, page: page, limit: limit, groups: "beats"), success: { json in
            let beats = json["data"].array?.map({ BeatsClient.beat(fromJson: $0) })
            let total = json["meta"]["total"].int
            success(beats, total)
        }, failure: failure)
    }

    @discardableResult
    func downloadedBeats(for uuid: String = shared.uuid(), page: Int, limit: Int, success: @escaping (_ beats: [Beat]?, _ total: Int?) -> Void, failure: @escaping (_ error: NSError) -> Void) -> DataRequest {
        return defaultRequest(Router.downloadedBeats(uuid: uuid, page: page, limit: limit), success: { json in
            let beats = json["data"].array?.map({ BeatsClient.beat(fromJson: $0) })
            let total = json["meta"]["total"].int
            success(beats, total)
        }, failure: failure)
    }

    static func user(fromJson json: JSON) -> User {
        var user = User()
        user.uuid = json["uuid"].string
        user.name = json["name"].string
        user.username = json["username"].string
        user.picture = json["profile_picture"].url
        user.reciprocal = json["reciprocal"].bool
        user.amFollowing = json["am_following"].bool
        user.followsMe = json["follows_me"].bool
        user.isANR = json["is_anr"].bool
        user.isVisibleInNearby = json["visible_in_nearby"].bool
        user.isVerified = json["is_verified"].bool

        return user
    }

    static func userFriend(fromJson json: JSON) -> UserFriend {
        let uuid = json["uuid"].string
        let name = json["name"].string
        let username = json["username"].string
        let email = json["email"].string
        let profileImageUrl = json["profile_picture"].string
        let isANR = json["is_anr"].bool
        //user.reciprocal = json["reciprocal"].bool
        let amFollowing = json["am_following"].bool
        let followsMe = json["follows_me"].bool
        //user.isANR = json["is_anr"].bool
        //user.isVisibleInNearby = json["visible_in_nearby"].bool


//        var canFollow: Bool = false
//        var following: Bool = false
//        var isANR: Bool = false
        let isVerifiedUser: Bool = json["is_verified"].boolValue

        return UserFriend(uuid: uuid, name: name, username: username, email: email, image: nil, profileImageUrl: profileImageUrl, followsMe: followsMe, following: amFollowing, isANR: isANR, isVerifiedUser: isVerifiedUser)
    }
}
