//
//  SearchResultsViewController.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/17/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import SwiftyJSON
import PagedArray


class SearchResultsViewController: KeyboardResizeUIViewController {
    @IBOutlet weak var musicContainerView: UIView!
    @IBOutlet weak var producersContainerView: UIView!
    @IBOutlet weak var videosContainerView: UIView!
    @IBOutlet weak var songsContainerView: UIView!
    @IBOutlet weak var usersContainerView: UIView!
    @IBOutlet weak var recentSearchContainerView: UIView!

    @IBOutlet weak var musicCollectionView: UICollectionView!
    @IBOutlet weak var producersCollectionView: UICollectionView!
    @IBOutlet weak var videosCollectionView: UICollectionView!
    @IBOutlet weak var songsCollectionView: UICollectionView!
    @IBOutlet weak var usersCollectionView: UICollectionView!
    @IBOutlet weak var recentSearchCollectionView: UICollectionView!
    
    var searchText = ""
    
    private lazy var recentSearches = SearchComponent(groups: "")
    private lazy var music = SearchComponent(groups: "beats")
    private lazy var producers = SearchComponent(groups: "producers")
    private lazy var videos = SearchComponent(groups: "videos")
    private lazy var songs = SearchComponent(groups: "songs")
    private lazy var users = SearchComponent(groups: "users")

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        UIApplication.shared.statusBarStyle = .default

        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        UIApplication.shared.statusBarStyle = .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let storyboard = UIStoryboard.init(name: "Helpers", bundle: nil)
        let searchBarVC = storyboard.instantiateViewController(withIdentifier: "SearchBarViewController") as! SearchBarViewController

        addChildViewController(searchBarVC)
        searchBarVC.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 100)
        self.view.addSubview(searchBarVC.view)

        searchBarVC.view.snp.makeConstraints { make in
            make.height.equalTo(100)
            make.width.equalTo(self.view.frame.size.width)
        }

        if let searchText = UserDefaults.standard.string(forKey: kRecentSearchesKey) {
            recentSearches.search(searchText, containerView: recentSearchContainerView, collectionView: recentSearchCollectionView)
            self.searchText = searchText
        }
    }

    func search(_ searchText: String) {
        recentSearchContainerView.isHidden = true
        music.search(searchText, containerView: musicContainerView, collectionView: musicCollectionView)
        producers.search(searchText, containerView: producersContainerView, collectionView: producersCollectionView)
        videos.search(searchText, containerView: videosContainerView, collectionView: videosCollectionView)
        songs.search(searchText, containerView: songsContainerView, collectionView: songsCollectionView)
        users.search(searchText, containerView: usersContainerView, collectionView: usersCollectionView)
        self.searchText = searchText
    }

    func playMusic(_ beat: JSON) {
        BeatsClient.shared.get(uuid: beat["uuid"].stringValue, success: { beat in
            let storyboard = UIStoryboard(name: "ARUser", bundle: Bundle.main)
            guard let viewController = storyboard.instantiateViewController(withIdentifier: "MediaPreviewViewController") as? MediaPreviewViewController else {
                fatalError("couldn't instantiate MediaPreviewViewController")
            }

            viewController.media = beat
//                viewController.delegate = self

            let navigationController = UINavigationController(rootViewController: viewController)
            navigationController.modalPresentationStyle = .overFullScreen

            self.present(navigationController, animated: true, completion: nil)
        }, failure: { error in })
    }

    func playVideo(_ video: JSON) {
        let storyboard = UIStoryboard(name: "Players", bundle: Bundle.main)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "MediaPlayerViewController") as? MediaPlayerViewController else {
            fatalError("couldn't instantiate MediaPlayerViewController")
        }

        viewController.media = VideosClient.video(fromJson: video)
        viewController.delegate = self

        let navigationController = UINavigationController(rootViewController: viewController)

        self.present(navigationController, animated: true, completion: nil)
    }

    func playSong(_ song: JSON) {
        play(SongsClient.song(fromJson: song))
    }
}

extension SearchResultsViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDataSourcePrefetching, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        func height(inAParticularRatioOfWidth width: Float) -> Float {
            let height: Float = width * 9 / 16
            return height
        }

        switch collectionView {
        case recentSearchCollectionView:
            return CGSize(width: 80, height: 120)
        case producersCollectionView, musicCollectionView, songsCollectionView:
            return CGSize(width: 80, height: 105)
        case videosCollectionView:
            let screenWidth = self.view.frame.size.width
            return CGSize(width: screenWidth / 2 - 2, height: CGFloat(height(inAParticularRatioOfWidth: Float(screenWidth / 2)) - 2))
        case usersCollectionView:
            return CGSize(width: 71, height: 95)
        default:
            return CGSize.zero
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView {
        case recentSearchCollectionView:
            return recentSearches.count()
        case musicCollectionView:
            return music.count()
        case producersCollectionView:
            return producers.count()
        case videosCollectionView:
            return videos.count()
        case songsCollectionView:
            return songs.count()
        case usersCollectionView:
            return users.count()
        default:
            return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell: SearchCell = SearchCell()
        var component: SearchComponent!

        switch (collectionView) {
        case recentSearchCollectionView:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RecentSearchCell", for: indexPath) as! RecentSearchCell
            component = recentSearches
        case musicCollectionView:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MusicSearchCell", for: indexPath) as! MusicSearchCell
            component = music
        case producersCollectionView:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProducerSearchCell", for: indexPath) as! ProducerSearchCell
            component = producers
        case videosCollectionView:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoSearchCell", for: indexPath) as! VideoSearchCell
            component = videos
        case songsCollectionView:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SongSearchCell", for: indexPath) as! SongSearchCell
            component = songs
        case usersCollectionView:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UserSearchCell", for: indexPath) as! UserSearchCell
            component = users
        default:
            break
        }

        if indexPath.row < component.count(), let data = component.item(at: indexPath) {
            cell.load(data)
        } else {
            cell.load()
        }
        
        component.loadDataIfNeeded(searchText, for: indexPath, on: collectionView)

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch collectionView {
        case recentSearchCollectionView:
            if let recent = recentSearches.item(at: indexPath) {
                switch recent["type"].stringValue {
                case "beats":
                    playMusic(recent)
                case "videos":
                    playVideo(recent)
                case "songs":
                    playSong(recent)
                case "users":
                    if recent["is_producer"].boolValue {
                        goToProducerProfile(with: recent["uuid"].stringValue)
                    } else {
                        goToProfile(uuid: recent["uuid"].stringValue, arUser: recent["is_anr"].boolValue)
                    }
                default:
                    break
                }
            }
        case musicCollectionView:
            if let beat = music.item(at: indexPath) {
                playMusic(beat)
            }
        case videosCollectionView:
            if let video = videos.item(at: indexPath) {
                playVideo(video)
            }
        case songsCollectionView:
            if let song = songs.item(at: indexPath) {
                playSong(song)
            }
        case usersCollectionView:
            if let user = users.item(at: indexPath) {
                goToProfile(uuid: user["uuid"].stringValue, arUser: user["is_anr"].boolValue)
            }
        case producersCollectionView:
            if let producer = producers.item(at: indexPath) {
                goToProducerProfile(with: producer["uuid"].stringValue)
            }
        default:
            print("AppDebug - Touched Item", indexPath.item)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        var component: SearchComponent!
        
        switch (collectionView) {
        case recentSearchCollectionView:
            component = recentSearches
        case musicCollectionView:
            component = music
        case producersCollectionView:
            component = producers
        case videosCollectionView:
            component = videos
        case songsCollectionView:
            component = songs
        case usersCollectionView:
            component = users
        default:
            break
        }
        
        indexPaths.forEach({ component.loadDataIfNeeded(searchText, for: $0, on: collectionView) })
    }

}

extension SearchResultsViewController: MediaPlayerViewControllerDelegate {
    func didDismiss(viewController: MediaPlayerViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }

    func didDeleteMedia(viewController: MediaPlayerViewController, media: Media) {
        viewController.dismiss(animated: true, completion: {
            // TODO: implement 2017-11-30 ()
        })
    }

    func didLikeMedia(viewController: MediaPlayerViewController, media: Media) {
        // TODO: implement 2017-11-30 (?)
    }

    func didCommentMedia(viewController: MediaPlayerViewController, media: Media) {
        viewController.dismiss(animated: true, completion: {
            // TODO: implement 2017-11-30 ()
        })
    }

    func didUpdateMediaInfo(viewController: MediaPlayerViewController, media: Media) {
        viewController.dismiss(animated: true, completion: {

        })
    }
}

