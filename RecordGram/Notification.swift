//
//  RGNotification.swift
//  RecordGram
//
//  Created by Mauro Taroco on 1/15/18.
//  Copyright © 2018 Meridian Inc. All rights reserved.
//

import SwiftyJSON

struct RGNotification {
    var uuid: String?
    var type: NotificationType?
    var body: String?
    var read: Bool?
    var timestamp: Date?
    var entity: String?
    var sender: User?
}

enum NotificationType {
    case none
    case commentLike
    case beatLike
    case songLike
    case videoLike
    case songComment
    case videoComment
    case songMention
    case songCommentMention
    case videoMention
    case videoCommentMention
    case derivativeSongUpload
    case derivativeVideoUpload
    case recordGramNotification
}


extension JSON {
    var notificationType: NotificationType? {
        if let type = string {
            switch type {
            case "beat_like":
                return .beatLike
            case "comment_like":
                return .commentLike
            case "song_like":
                return .songLike
            case "video_like":
                return .videoLike
            case "song_comment":
                return .songComment
            case "video_comment":
                return .videoComment
            case "song_mention":
                return .songMention
            case "song_comment_mention":
                return .songCommentMention
            case "video_mention":
                return .videoMention
            case "video_comment_mention":
                return .videoCommentMention
            case "derivative_song_upload":
                return .derivativeSongUpload
            case "derivative_video_upload":
                return .derivativeVideoUpload
            default:
                return .recordGramNotification
            }
        } else {
            return .none
        }
    }
}

/*

 Possible notifications type:
 
 const BEAT_LIKE = 'beat_like';                              // alice likes bob's beat
 const COMMENT_LIKE = 'comment_like';                        // alice likes bob's comment
 const SONG_LIKE = 'song_like';                              // alice likes bob's song
 const VIDEO_LIKE = 'video_like';                            // alice likes bob's video
 
 const SONG_COMMENT = 'song_comment';                        // alice comments on bob's song
 const VIDEO_COMMENT = 'video_comment';                      // alice comments on bob's video
 
 const SONG_MENTION = 'song_mention';                        // alice mentions bob on a song description
 const SONG_COMMENT_MENTION = 'song_comment_mention';        // alice mentions bob on a comment on a song
 const VIDEO_MENTION = 'video_mention';                      // alice mentions bob on a video description
 const VIDEO_COMMENT_MENTION = 'video_comment_mention';      // alice mentions bob on a comment on a video
 
 const DERIVATIVE_SONG_UPLOAD = 'derivative_song_upload';    // alice publishes a song from bob's beat
 const DERIVATIVE_VIDEO_UPLOAD = 'derivative_video_upload';  // alice publishes a video from bob's beat
 
 */
