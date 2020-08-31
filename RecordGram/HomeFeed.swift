//
//  HomeFeed.swift
//  RecordGram
//
//  Created by Hugo Prione on 18/09/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import Foundation

struct HomeFeed {
    var uuid: String?
    var title: String?
    var coordinates: Coordinates?
    var type: String?
    var url: String?
    var gif: String?
    var thumbnail: String?
    var user: User?
    var beat: Beat?
    var producer: Producer?

    lazy var asMedia: Media? = {
        if let type = type {
            var media: Media
            if type == "videos" {
                media = Video()
            } else {
                media = Song()
            }
            if let url = url {
                media.url = URL(string: url)
            }
            media.name = title
            media.uuid = uuid
            media.isPublic = true
            media.user = user

            return media
        }
        return nil
    }()

    lazy var asVideo: Video? = {
        if let type = type, type == "videos" {
            var video = Video()
            if let gif = gif {
                video.gif = URL(string: gif)
            }
            if let thumb = thumbnail {
                video.thumb = URL(string: thumb)
            }
            if let url = url {
                video.url = URL(string: url)
            }
            video.name = title
            video.uuid = uuid
            video.isPublic = true
            video.user = user

            return video
        }
        return nil
    }()

    lazy var asSong: Song? = {
        if let type = type, type == "songs" {
            var song = Song()

            if let thumbnail = thumbnail {
                song.thumbnail = URL(string: thumbnail)
            }

            song.uuid = uuid
            song.name = title
            song.user = user


            if let url = url {
                song.url = URL(string: url)
            }

            let beat = self.beat ?? Beat()
            beat.producer = producer

            song.beat = beat

            return song
        }
        return nil
    }()
}
