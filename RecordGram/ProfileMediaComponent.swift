//
//  MediaComponent.swift
//  RecordGram
//
//  Created by Nicolas Gonzalez on 12/11/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import PagedArray
import Foundation

class ProfileMediaComponent {

    var array = PagedArray<Media>(count: 0, pageSize: 0)
    var pagesLoading = [Int]()
    var indexPaths = [IndexPath]()

    var limit: Int

    init(limit: Int = 9) {
        self.limit = limit
    }

    func loadSong(uuid: String, collectionView: UICollectionView?) {
        UserClient.shared.songs(for: uuid, page: 1, limit: limit, success: { media, total in
            if let count = total, count > 0, let media = media {
                self.array = PagedArray<Media>(count: count, pageSize: self.limit)
                self.array.set(media, forPage: 0)
                if let collectionView = collectionView {
                    collectionView.reloadData()
                }
            }
        }, failure: { _ in })
    }

    func loadVideo(uuid: String, collectionView: UICollectionView?) {
        UserClient.shared.videos(for: uuid, page: 1, limit: limit, success: { media, total in
            if let count = total, count > 0, let media = media {
                self.array = PagedArray<Media>(count: count, pageSize: self.limit)
                self.array.set(media, forPage: 0)
                if let collectionView = collectionView {
                    collectionView.reloadData()
                }
            }
        }, failure: { _ in })
    }

    func loadScoutSongs(uuid: String, collectionView: UICollectionView?) {
        UserClient.shared.likedSongs(for: uuid, page: 1, limit: limit, success: { media, total in
            if let count = total, count > 0, let media = media {
                self.array = PagedArray<Media>(count: count, pageSize: self.limit)
                self.array.set(media, forPage: 0)
                if let collectionView = collectionView {
                    collectionView.reloadData()
                }
            }
        }, failure: { _ in })
    }

    func loadScoutVideos(uuid: String, collectionView: UICollectionView?) {
        UserClient.shared.likedVideos(for: uuid, page: 1, limit: limit, success: { media, total in
            if let count = total, count > 0, let media = media {
                self.array = PagedArray<Media>(count: count, pageSize: self.limit)
                self.array.set(media, forPage: 0)
                if let collectionView = collectionView {
                    collectionView.reloadData()
                }
            }
        }, failure: { _ in })
    }

    func loadSongDataIfNeeded(uuid: String, for indexPath: IndexPath, collectionView: UICollectionView) {
        self.indexPaths.append(indexPath)
        let currentPage = self.array.page(for: indexPath.row)
        if self.array.elements[currentPage] == nil && !self.pagesLoading.contains(currentPage) {
            self.pagesLoading.append(currentPage)
            UserClient.shared.songs(for: uuid, page: currentPage + 1, limit: limit, success: { songs, _ in
                if let songs = songs {
                    self.array.set(songs, forPage: currentPage)
                    let indexPathsToReload = Array(Set(collectionView.indexPathsForVisibleItems + self.indexPaths)).filter({ self.array.indexes(for: currentPage).contains($0.row) })
                    self.indexPaths = []
                    if indexPathsToReload.count > 0 {
//                        collectionView.reloadItems(at: indexPathsToReload)
                        collectionView.reloadData()
                    }
                    self.pagesLoading.remove(at: self.pagesLoading.index(of: currentPage)!)
                }
            }, failure: { _ in })
        }
    }

    func loadVideoDataIfNeeded(uuid: String, for indexPath: IndexPath, collectionView: UICollectionView) {
        self.indexPaths.append(indexPath)
        let currentPage = self.array.page(for: indexPath.row)
        if self.array.elements[currentPage] == nil && !self.pagesLoading.contains(currentPage) {
            self.pagesLoading.append(currentPage)
            UserClient.shared.videos(for: uuid, page: currentPage + 1, limit: limit, success: { videos, _ in
                if let videos = videos {
                    self.array.set(videos, forPage: currentPage)
                    let indexPathsToReload = Array(Set(collectionView.indexPathsForVisibleItems + self.indexPaths)).filter({ self.array.indexes(for: currentPage).contains($0.row) })
                    self.indexPaths = []
                    if indexPathsToReload.count > 0 {
//                        collectionView.reloadItems(at: indexPathsToReload)
                        collectionView.reloadData()
                    }
                    self.pagesLoading.remove(at: self.pagesLoading.index(of: currentPage)!)
                }
            }, failure: { _ in })
        }
    }

    func loadScoutSongDataIfNeeded(uuid: String, for indexPath: IndexPath, collectionView: UICollectionView) {
        self.indexPaths.append(indexPath)
        let currentPage = self.array.page(for: indexPath.row)
        if self.array.elements[currentPage] == nil && !self.pagesLoading.contains(currentPage) {
            self.pagesLoading.append(currentPage)
            UserClient.shared.likedSongs(for: uuid, page: currentPage + 1, limit: limit, success: { songs, _ in
                if let songs = songs {
                    self.array.set(songs, forPage: currentPage)
                    let indexPathsToReload = Array(Set(collectionView.indexPathsForVisibleItems + self.indexPaths)).filter({ self.array.indexes(for: currentPage).contains($0.row) })
                    self.indexPaths = []
                    if indexPathsToReload.count > 0 {
//                        collectionView.reloadItems(at: indexPathsToReload)
                        collectionView.reloadData()
                    }
                    self.pagesLoading.remove(at: self.pagesLoading.index(of: currentPage)!)
                }
            }, failure: { _ in })
        }
    }

    func loadScoutVideoDataIfNeeded(uuid: String, for indexPath: IndexPath, collectionView: UICollectionView) {
        self.indexPaths.append(indexPath)
        let currentPage = self.array.page(for: indexPath.row)
        if self.array.elements[currentPage] == nil && !self.pagesLoading.contains(currentPage) {
            self.pagesLoading.append(currentPage)
            UserClient.shared.likedVideos(for: uuid, page: currentPage + 1, limit: limit, success: { videos, _ in
                if let videos = videos {
                    self.array.set(videos, forPage: currentPage)
                    let indexPathsToReload = Array(Set(collectionView.indexPathsForVisibleItems + self.indexPaths)).filter({ self.array.indexes(for: currentPage).contains($0.row) })
                    self.indexPaths = []
                    if indexPathsToReload.count > 0 {
//                        collectionView.reloadItems(at: indexPathsToReload)
                        collectionView.reloadData()
                    }
                    self.pagesLoading.remove(at: self.pagesLoading.index(of: currentPage)!)
                }
            }, failure: { _ in })
        }
    }
}
