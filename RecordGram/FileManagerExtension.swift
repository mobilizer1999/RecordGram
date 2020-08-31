//
//  FileManagerExtension.swift
//  RecordGram
//
//  Created by Hugo Prione on 01/11/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import Foundation

extension FileManager {
    func beatsFolderPath() throws -> URL {
        guard let documentsPath = urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError()
        }
        let folderPath = documentsPath.appendingPathComponent("beats")
        if !fileExists(atPath: folderPath.path) {
            try createDirectory(at: folderPath, withIntermediateDirectories: false, attributes: nil)
        }
        return folderPath
    }
    
    func songsFolderPath() throws -> URL {
        guard let documentsPath = urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError()
        }
        let folderPath = documentsPath.appendingPathComponent("songs")
        if !fileExists(atPath: folderPath.path) {
            try createDirectory(at: folderPath, withIntermediateDirectories: false, attributes: nil)
        }
        return folderPath
    }
    
    func videosFolderPath() throws -> URL {
        guard let documentsPath = urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError()
        }
        let folderPath = documentsPath.appendingPathComponent("videos")
        if !fileExists(atPath: folderPath.path) {
            try createDirectory(at: folderPath, withIntermediateDirectories: false, attributes: nil)
        }
        return folderPath
    }
    
    func tempFolderPath() throws -> URL {
        guard let documentsPath = urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError()
        }
        let folderPath = documentsPath.appendingPathComponent("temp")
        if !fileExists(atPath: folderPath.path) {
            try createDirectory(at: folderPath, withIntermediateDirectories: false, attributes: nil)
        }
        return folderPath
    }
    
    func folderPath(forMedia media: Media) throws -> URL {
        var pathExtension: String?
        if let url = media.url, url.absoluteString.range(of: ".mp3") != nil {
            pathExtension = "mp3"
        }
        
        if let beat = media as? Beat {
            return try beatsFolderPath().appendingPathComponent(beat.uuid ?? "").appendingPathExtension(pathExtension ?? "m4a")
        }
        
        if let song = media as? Song {
            return try songsFolderPath().appendingPathComponent(song.uuid ?? "").appendingPathExtension(pathExtension ?? "m4a")
        }
        
        if let video = media as? Video {
            return try videosFolderPath().appendingPathComponent(video.uuid ?? "").appendingPathExtension("mp4")
        }
        
        fatalError("media type not implemented")
    }
    
    func tempFolderPath(forMedia media: Media, deleteExisting: Bool = true) throws -> URL {
        var url = try tempFolderPath().appendingPathComponent(media.uuid ?? "")
        
        if let _ = media as? Beat {
            url = url.appendingPathExtension("m4a")
        } else if let _ = media as? Song {
            url = url.appendingPathExtension("m4a")
        } else if let _ = media as? Video {
            url = url.appendingPathExtension("mp4")
        } else {
            fatalError("media type not implemented")
        }
        
        if deleteExisting && fileExists(atPath: url.path) {
            try removeItem(at: url)
        }
        
        return url
    }
    
    // TODO: refactor 2017-12-07 remove (?)
    func tempFolderPathCropped(forMedia media: Media, deleteExisting: Bool = true) throws -> URL {
        var url = try tempFolderPath().appendingPathComponent("cropped-\(media.uuid ?? "")")
        
        if let _ = media as? Beat {
            url = url.appendingPathExtension("m4a")
        } else if let _ = media as? Song {
            url = url.appendingPathExtension("m4a")
        } else if let _ = media as? Video {
            url = url.appendingPathExtension("mp4")
        } else {
            fatalError("media type not implemented")
        }
        
        if deleteExisting && fileExists(atPath: url.path) {
            try removeItem(at: url)
        }
        
        return url
    }
    
    func tempFolderForProcessingAudio(deleteExisting: Bool = true) throws -> URL {
        let url = try tempFolderPath().appendingPathComponent("song").appendingPathExtension("m4a")
        
        if deleteExisting && fileExists(atPath: url.path) {
            try removeItem(at: url)
        }
        
        return url
    }

    func tempFolderForProcessingSong(deleteExisting: Bool = true) throws -> URL {
        let url = try songsFolderPath().appendingPathComponent("uploading").appendingPathExtension("m4a")

        if deleteExisting && fileExists(atPath: url.path) {
            try removeItem(at: url)
        }

        return url
    }
    
    func tempFolderForProcessingVideo(deleteExisting: Bool = true) throws -> URL {
        let url = try tempFolderPath().appendingPathComponent("video").appendingPathExtension("mp4")
        
        if deleteExisting && fileExists(atPath: url.path) {
            try removeItem(at: url)
        }
        
        return url
    }
    
    func tempFolderForProcessingClip(index: Int, deleteExisting: Bool = true) throws -> URL {
        let url = try tempFolderPath().appendingPathComponent("clip\(index)").appendingPathExtension("mp4")
        
        if deleteExisting && fileExists(atPath: url.path) {
            try removeItem(at: url)
        }
        
        return url
    }
}
