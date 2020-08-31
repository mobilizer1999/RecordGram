//
//  NotificationsClient.swift
//  RecordGram
//
//  Created by Nicolas Gonzalez on 3/14/18.
//  Copyright © 2018 Meridian Inc. All rights reserved.
//

import SwiftyJSON
import Alamofire

class NotificationsClient: Client {

    static let shared = NotificationsClient()

    enum Router: URLRequestConvertible {
        case get(page: Int)
        case readAll
        case preferences
        case savePreferences(parameters: Parameters)
        case delete(uuid: String)
        case deleteAll

        static let limit = 10

        var method: HTTPMethod {
            switch self {
            case .get, .preferences:
                return .get
            case .readAll:
                return .post
            case .savePreferences:
                return .put
            case .delete, .deleteAll:
                return .delete
            }
        }

        var endpoint: String {
            switch self {
            case .get:
                return "notifications"
            case .readAll:
                return "notifications/read-all"
            case .preferences, .savePreferences:
                return "notification-preferences"
            case .delete(let uuid):
                return "notifications/\(uuid)"
            case .deleteAll:
                return "notifications/delete-all"
            }
        }

        func asURLRequest() throws -> URLRequest {
            var urlRequest = URLRequest(url: try UserClient.shared.apiUrl(endpoint: endpoint).asURL())
            urlRequest.httpMethod = method.rawValue

            switch self {
            case .savePreferences(let parameters):
                urlRequest = try URLEncoding.default.encode(urlRequest, with: parameters)
            case .get(let page):
                urlRequest = try URLEncoding.default.encode(urlRequest, with: [
                    "page": page,
                    "limit": Router.limit
                ])
            default:
                break
            }

            return urlRequest
        }
    }

    @discardableResult
    func get(page: Int, success: @escaping (_ notifications: [RGNotification]?, _ total: Int?, _ limit: Int) -> Void, failure: @escaping (_ error: NSError) -> Void) -> DataRequest {
        return defaultRequest(Router.get(page: page), success: { json in
            let notifications = json["data"].array?.map({ NotificationsClient.notification(from: $0) })
            let total = json["meta"]["total"].int
            
            success(notifications, total, Router.limit)
        }, failure: failure)
    }

    func readAll() {
        defaultRequest(Router.readAll, success: { _ in }, failure: { _ in })
    }

    func preferences(success: @escaping (_ notifications: NotificationPreferences) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequest(Router.preferences, success: { json in
            success(NotificationsClient.preferences(from: json["data"]))
        }, failure: failure)
    }

    func savePreferences(parameters: Parameters, success: @escaping () -> Void, failure: @escaping (_ error: NSError) -> Void) {
        defaultRequestNoResponse(Router.savePreferences(parameters: parameters), success: success, failure: failure)
    }

    func delete(uuid: String, success: @escaping () -> Void) {
        defaultRequestNoResponse(Router.delete(uuid: uuid), success: success, failure: { _ in })
    }

    func deleteAll() {
        defaultRequest(Router.deleteAll, success: { _ in }, failure: { _ in })
    }

    static func notification(from json: JSON) -> RGNotification {
        var notification = RGNotification()

        notification.uuid = json["uuid"].string
        notification.type = json["type"].notificationType
        notification.body = json["body"].string
        notification.read = json["read"].bool

        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .none
        dateFormatter.dateStyle = .none
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        if let rawDate = json["timestamp"].string {
            notification.timestamp = dateFormatter.date(from: rawDate)
        }

        notification.entity = json["entity"].string
        notification.sender = UserClient.user(fromJson: json["sender"])

        return notification
    }

    static func preferences(from json: JSON) -> NotificationPreferences {
        var preferences = NotificationPreferences()
        preferences.beatLike = json["beat_like"].bool
        preferences.commentLike = json["comment_like"].bool
        preferences.songLike = json["song_like"].bool
        preferences.videoLike = json["video_like"].bool
        preferences.songComment = json["song_comment"].bool
        preferences.videoComment = json["video_comment"].bool
        preferences.songMention = json["song_mention"].bool
        preferences.songCommentMention = json["song_comment_mention"].bool
        preferences.videoMention = json["video_mention"].bool
        preferences.videoCommentMention = json["video_comment_mention"].bool
        preferences.derivativeSongUpload = json["derivative_song_upload"].bool
        preferences.derivativeVideoUpload = json["derivative_video_upload"].bool
        preferences.admin = json["admin"].bool

        return preferences
    }
}
