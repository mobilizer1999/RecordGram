//
//  ContestDetailsViewController.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 10/11/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.

import UIKit

class ContestDetailsViewController: UIViewController {

    var contest: Contest?
    var refreshControl: UIRefreshControl!

    private var videos: [Video] = []
    private var songs: [Song] = []
    private var dataSource: [Any] = []
    var mode = Mode.video

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var videosButton: UIBorderBottomButton!
    @IBOutlet weak var songsButton: UIBorderBottomButton!
    @IBOutlet weak var contestViewImage: UIImageView!

    let mediaPlaceholder = UIImage(named: "media_placeholder")

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "#\(contest?.hashtag ?? "")"
        self.navigationController?.navigationBar.topItem?.title = ""
        let backButtonImage = UIImage(named: "backArrow")
        self.navigationController?.navigationBar.backIndicatorImage = backButtonImage
        self.navigationController?.navigationBar.backIndicatorTransitionMaskImage = backButtonImage

        refreshControl = UIRefreshControl()
        refreshControl.tintColor = .themeColor
        refreshControl.addTarget(self, action: #selector(refresh), for: UIControlEvents.valueChanged)
        //tableView.addSubview(refreshControl)
        //self.collectionView.register(ContestCollectionCellCollectionViewCell.self, forCellWithReuseIdentifier: "contestCell")

        self.getContestDetails()

        if let thumbnail = contest?.thumbnail {
            contestViewImage.kf.setImage(with: thumbnail, placeholder: #imageLiteral(resourceName:"gradientButtonBG"))
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
        tabBarController?.tabBar.isTranslucent = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }

    func getContestDetails() {
        getSongs()
        getVideos()
    }

    func getSongs() {
        ContestsClient.shared.allSongs(uuid: (contest?.uuid)!, success: { (songs) in
            //TODO: show all songs
            self.songs = songs ?? []
            self.refreshControl.endRefreshing()
        }, failure: { error in
            //TODO: show Errors
            self.refreshControl.endRefreshing()
        })
    }

    func getVideos() {
        ContestsClient.shared.allVideos(uuid: (contest?.uuid)!, success: { (videos) in
            //TODO: show all videos
            self.videos = videos ?? []
            self.refreshControl.endRefreshing()
            self.reloadDataSource(isVideo: self.mode == .video)

        }, failure: { error in
            //TODO: show Errors
            self.refreshControl.endRefreshing()
        })
    }

    @objc func refresh(sender: AnyObject) {
        getContestDetails()
    }

    @IBAction func didPressVideos(_ sender: UIButton) {
        dataSource = videos
        videosButton.isSelected = true
        songsButton.isSelected = false
        reloadDataSource(isVideo: true)
        mode = .video
    }

    @IBAction func didPressSongsVideo(_ sender: UIBorderBottomButton) {
        dataSource = songs
        videosButton.isSelected = false
        songsButton.isSelected = true
        reloadDataSource(isVideo: false)
        mode = .song
    }

    func reloadDataSource(isVideo: Bool) {
        if isVideo {
            dataSource = videos
        } else {
            dataSource = songs
        }
        collectionView.reloadData()
    }

}

extension ContestDetailsViewController: MySongOptionsViewControllerDelegate {
    func didTapShootVideoButton(song: Song, viewController: MySongOptionsViewController) {
    }

    func didTapPlaySongButton(song: Song, viewController: MySongOptionsViewController) {
    }

    func didTapShareSongButton(song: Song, viewController: MySongOptionsViewController) {
    }

    func didTapMakePublicButton(song: Song, viewController: MySongOptionsViewController) {
    }

    func didTapUpdateSongInfoButton(song: Song, viewController: MySongOptionsViewController) {
    }

    func didTapAddVocalsButton(song: Song, viewController: MySongOptionsViewController) {
    }

    func didTapDeleteSongButton(song: Song, viewController: MySongOptionsViewController) {
    }

    func didTapCloseButton(song: Song, viewController: MySongOptionsViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
}


extension ContestDetailsViewController: MediaPlayerViewControllerDelegate {
    func didDismiss(viewController: MediaPlayerViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }

    func didDeleteMedia(viewController: MediaPlayerViewController, media: Media) {
    }

    func didUpdateMediaInfo(viewController: MediaPlayerViewController, media: Media) {
    }
}

extension ContestDetailsViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.dataSource.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch mode {
        case .song:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SongCell", for: indexPath) as? SongCollectionViewCell else {
                fatalError()
            }
            let song = songs[indexPath.row]

            cell.setup(with: song)

            return cell
        case .video:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "contestCellVideo", for: indexPath) as? VideoCollectionViewCell else {
                fatalError()
            }
            let video = videos[indexPath.row]

            cell.imgPreview.image = mediaPlaceholder
            
            
            cell.loadImg(for: video)
            
            
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let song = dataSource[indexPath.row] as? Song {
            play(song)
        } else {
            let storyboard = UIStoryboard(name: "Players", bundle: Bundle.main)
            guard let viewController = storyboard.instantiateViewController(withIdentifier: "MediaPlayerViewController") as? MediaPlayerViewController else {
                fatalError("couldn't instantiate MediaPlayerViewController")
            }

            viewController.media = dataSource[indexPath.row] as? Media
            viewController.delegate = self

            let navigationController = UINavigationController(rootViewController: viewController)
            self.present(navigationController, animated: true, completion: nil)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch mode {
        case .song:
            return CGSize(width: view.frame.width, height: 85)
        case .video:
            let width: CGFloat = (view.frame.width / 3.0).rounded(.down)
            let height: CGFloat = (width * 16) / 9
            return CGSize(width: width, height: height)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}
    


