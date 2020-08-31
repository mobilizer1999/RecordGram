//
//  CreationsViewController.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/5/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit

enum Mode {
    case song, video
}

enum Action {
    case shootVideo, addVocals
}

class CreationsViewController: UIViewController, ErrorHandler {

    @IBOutlet var btnTabs: [UIButton]!
    @IBOutlet weak var collectionMedia: UICollectionView!
    @IBOutlet weak var profileNavButton: UIButton!

    var menuVC: MenuViewController!
    var menuView: UIView!

    private var songs = ProfileMediaComponent(limit: 12)
    private var videos = ProfileMediaComponent(limit: 12)
    var mode = Mode.video
    private var action = Action.shootVideo // TODO: 2018-01-18 refactor find better way (?)

    var showBack = false

    let placeholder = #imageLiteral(resourceName:"media_placeholder")

    override func viewDidLoad() {
        super.viewDidLoad()

        btnTabs[0].isSelected = mode == .video
        btnTabs[1].isSelected = mode == .song

        if showBack {
            navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName:"backArrow"), style: .plain, target: self, action: #selector(NotificationsViewController.onBackButton))
            tabBarController?.tabBar.isHidden = true
            tabBarController?.tabBar.isTranslucent = true
        } else {
            insertMenu()
        }

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        load(profileNavButton)

        loadMedia()
    }

    func loadMedia() {
        videos.loadVideo(uuid: UserClient.shared.uuid(), collectionView: collectionMedia)
        songs.loadSong(uuid: UserClient.shared.uuid(), collectionView: nil)
    }

    @objc func onBackButton() {
        navigationController?.popViewController(animated: true)
    }

    func insertMenu() {
        if let window = UIApplication.shared.keyWindow {
            let storyboard = UIStoryboard(name: "Menu", bundle: nil)
            menuVC = storyboard.instantiateViewController(withIdentifier: "menu") as! MenuViewController
            menuVC.creationsVC = self
            menuView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
            menuView.isUserInteractionEnabled = false
            menuView.addSubview(menuVC.view)
            window.addSubview(menuView)
        }
    }

    @IBAction func onMenuButton(_ sender: Any) {
        menuVC.openMenu()
        menuView.isUserInteractionEnabled = true;
    }

    @IBAction func didTapMySongsButton(_ sender: UIButton) {
        mode = .song

        btnTabs.forEach { (btn) in
            btn.isSelected = btn == sender
        }
        collectionMedia.reloadData()
    }

    @IBAction func didTapMyVideosButton(_ sender: UIButton) {
        mode = .video

        btnTabs.forEach { (btn) in
            btn.isSelected = btn == sender
        }
        collectionMedia.reloadData()
    }
}

extension CreationsViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch mode {
        case .song:
            return songs.array.count
        case .video:
            return videos.array.count
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

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch mode {
        case .song:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SongCell", for: indexPath) as? SongCollectionViewCell else {
                fatalError()
            }
            if let song = songs.array[indexPath.item] as? Song {
                cell.setup(with: song)
            } else {
                cell.clear()
                songs.loadSongDataIfNeeded(uuid: UserClient.shared.uuid(), for: indexPath, collectionView: collectionView)
            }

            return cell
        case .video:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoCell", for: indexPath) as? VideoCollectionViewCell else {
                fatalError()
            }

            cell.imgPreview.image = placeholder

            if let video = videos.array[indexPath.item] as? Video {
                cell.loadImg(for: video)
            } else {
                videos.loadVideoDataIfNeeded(uuid: UserClient.shared.uuid(), for: indexPath, collectionView: collectionView)
            }

            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch mode {
        case .song:
            guard let song = songs.array[indexPath.row] as? Song else {
                return
            }
            play(song)
        case .video:
            let storyboard = UIStoryboard(name: "Players", bundle: Bundle.main)
            guard let viewController = storyboard.instantiateViewController(withIdentifier: "MediaPlayerViewController") as? MediaPlayerViewController else {
                fatalError("couldn't instantiate MediaPlayerViewController")
            }

            guard let video = videos.array[indexPath.row] as? Video else {
                return
            }

            viewController.media = video
            viewController.delegate = self

            let navigationController = UINavigationController(rootViewController: viewController)

            self.present(navigationController, animated: true, completion: nil)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

extension CreationsViewController: MySongOptionsViewControllerDelegate {
    func didTapShootVideoButton(song: Song, viewController: MySongOptionsViewController) {
        viewController.dismiss(animated: true) {
            var fileExists: Bool!

            do {
                let url = try FileManager.default.folderPath(forMedia: song)

                fileExists = FileManager.default.fileExists(atPath: url.path)
            } catch let error {
                self.presentErrorDialog(error: error)
                return
            }

            if !fileExists { // download song
                self.action = .shootVideo

                let storyboard = UIStoryboard(name: "ARUser", bundle: Bundle.main)
                guard let viewController = storyboard.instantiateViewController(withIdentifier: "MediaDownloaderViewController") as? MediaDownloaderViewController else {
                    fatalError("couldn't instantiate MediaDownloaderViewController")
                }

                viewController.media = song
                viewController.delegate = self

                let navigationController = UINavigationController(rootViewController: viewController)
                navigationController.modalPresentationStyle = .overFullScreen

                self.present(navigationController, animated: true, completion: nil)
                return
            }

            let storyboard = UIStoryboard(name: "ARUser", bundle: Bundle.main)
            guard let viewController = storyboard.instantiateViewController(withIdentifier: "TrimAudioViewController") as? TrimAudioViewController else {
                fatalError("couldn't instantiate TrimAudioViewController")
            }

            viewController.media = song
            viewController.delegate = self

            self.present(viewController, animated: true, completion: nil)
        }
    }

    func didTapPlaySongButton(song: Song, viewController: MySongOptionsViewController) {
        viewController.dismiss(animated: true) {
            let storyboard = UIStoryboard(name: "Players", bundle: Bundle.main)
            guard let viewController = storyboard.instantiateViewController(withIdentifier: "MediaPlayerViewController") as? MediaPlayerViewController else {
                fatalError("couldn't instantiate MediaPlayerViewController")
            }

            viewController.media = song
            viewController.delegate = self

            let navigationController = UINavigationController(rootViewController: viewController)

            self.present(navigationController, animated: true, completion: nil)
        }
    }

    func didTapShareSongButton(song: Song, viewController: MySongOptionsViewController) {
        viewController.dismiss(animated: true) {
            guard let uuid = song.uuid else {
                return
            }

            let url = "http://view.cre8tor.app/\(uuid)"
            let username = song.user?.toString() ?? NSLocalizedString("Unknown", comment: "Unknown username")
            let message = String(format: NSLocalizedString("Check this out. It was made on @Cre8tor by %@.", comment: "Share"), username)
            let items: [Any] = [message, url]
            
            let activityController = UIActivityViewController(activityItems: items, applicationActivities: nil)
            activityController.popoverPresentationController?.sourceView = self.view
            activityController.popoverPresentationController?.sourceRect = self.view.frame

            self.present(activityController, animated: true, completion: nil)
        }
    }

    func didTapMakePublicButton(song: Song, viewController: MySongOptionsViewController) {
        viewController.dismiss(animated: true) {
            song.isPublic = true

            SongsClient.shared.update(song: song, success: { song in
                // no-op
            }, failure: { error in
                self.presentErrorDialog(error: error)
            })
        }
    }

    func didTapUpdateSongInfoButton(song: Song, viewController: MySongOptionsViewController) {
        viewController.dismiss(animated: true) {
            let storyboard = UIStoryboard(name: "VideoCapture", bundle: Bundle.main)
            guard let viewController = storyboard.instantiateViewController(withIdentifier: "SaveMediaViewController") as? SaveMediaViewController else {
                fatalError("couldn't instantiate SaveMediaViewController")
            }

            viewController.media = song
            viewController.delegate = self

            let navigationController = UINavigationController(rootViewController: viewController)
            navigationController.modalPresentationStyle = .overCurrentContext

            self.present(navigationController, animated: true, completion: nil)
        }
    }

    func didTapAddVocalsButton(song: Song, viewController: MySongOptionsViewController) {
        viewController.dismiss(animated: true) {
            var fileExists: Bool!
            do {
                let url = try FileManager.default.folderPath(forMedia: song)

                fileExists = FileManager.default.fileExists(atPath: url.path)
            } catch let error {
                self.presentErrorDialog(error: error)
                return
            }

            if !fileExists { // download song
                self.action = .addVocals

                let storyboard = UIStoryboard(name: "ARUser", bundle: Bundle.main)
                guard let viewController = storyboard.instantiateViewController(withIdentifier: "MediaDownloaderViewController") as? MediaDownloaderViewController else {
                    fatalError("couldn't instantiate MediaDownloaderViewController")
                }

                viewController.media = song
                viewController.delegate = self

                let navigationController = UINavigationController(rootViewController: viewController)
                navigationController.modalPresentationStyle = .overFullScreen

                self.present(navigationController, animated: true, completion: nil)
                return
            }

            // TODO: 2018-01-02 refactor find better way
            guard let navigationController = self.tabBarController?.viewControllers?[2] as? UINavigationController else {
                return
            }
            guard let studioViewController = navigationController.viewControllers.first as? StudioViewController else {
                return
            }
            navigationController.popToRootViewController(animated: false)
            self.tabBarController?.selectedIndex = 2
            DispatchQueue.main.async {
                studioViewController.media = song
            }
        }
    }

    func didTapDeleteSongButton(song: Song, viewController: MySongOptionsViewController) {
        viewController.dismiss(animated: true) {
            guard let uuid = song.uuid else {
                return
            }
            SongsClient.shared.delete(uuid: uuid, success: {
                self.songs.loadSong(uuid: UserClient.shared.uuid(), collectionView: self.collectionMedia)
            }, failure: { error in
                self.presentErrorDialog(error: error)
            })
        }
    }

    func didTapCloseButton(song: Song, viewController: MySongOptionsViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
}

// TODO: refactor 2017-11-28 (simplify workflow or centralize in a router)
extension CreationsViewController: MediaDownloaderViewControllerDelegate {

    func didDownloadMedia(viewController: MediaDownloaderViewController, media: Media, url: URL) {
        viewController.close {
            switch self.action {
            case .shootVideo:
                let storyboard = UIStoryboard(name: "ARUser", bundle: Bundle.main)
                guard let viewController = storyboard.instantiateViewController(withIdentifier: "TrimAudioViewController") as? TrimAudioViewController else {
                    fatalError("couldn't instantiate TrimAudioViewController")
                }

                viewController.media = media
                viewController.delegate = self

                self.present(viewController, animated: true, completion: nil)
            case .addVocals:
                // TODO: 2018-01-02 refactor find better way
                guard let navigationController = self.tabBarController?.viewControllers?[2] as? UINavigationController else {
                    return
                }
                guard let studioViewController = navigationController.viewControllers.first as? StudioViewController else {
                    return
                }
                navigationController.popToRootViewController(animated: false)
                self.tabBarController?.selectedIndex = 2
                DispatchQueue.main.async {
                    studioViewController.media = media
                }
            }
        }
    }
}

extension CreationsViewController: TrimAudioViewControllerDelegate {
    func didDismiss(viewController: TrimAudioViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }

    func didTrimMedia(viewController: TrimAudioViewController, media: Media, output: URL) {
        viewController.dismiss(animated: true) {
            let storyboard = UIStoryboard(name: "VideoCapture", bundle: Bundle.main)
            guard let viewController = storyboard.instantiateViewController(withIdentifier: "CaptureVideoViewController") as? CaptureVideoViewController else {
                fatalError("couldn't instantiate CaptureVideoViewController")
            }

            viewController.url = output
            viewController.base = media
            viewController.delegate = self

            let navigationController = UINavigationController(rootViewController: viewController)

            self.present(navigationController, animated: true, completion: nil)
        }
    }
}

extension CreationsViewController: CaptureVideoViewControllerDelegate {
    func didCaptureVideo(viewController: CaptureVideoViewController, base: Media?, outputUrl: URL) {
        let storyboard = UIStoryboard(name: "VideoCapture", bundle: Bundle.main)
        guard let filtersViewController = storyboard.instantiateViewController(withIdentifier: "VideoFiltersViewController") as? VideoFiltersViewController else {
            return
        }

        filtersViewController.url = outputUrl
        filtersViewController.base = base
        filtersViewController.delegate = self

        viewController.navigationController?.pushViewController(filtersViewController, animated: true)
    }

    func didCancel(viewController: CaptureVideoViewController) {
        viewController.navigationController?.dismiss(animated: true, completion: nil)
    }
}

extension CreationsViewController: VideoFiltersViewControllerDelegate {
    func didConfirm(viewController: VideoFiltersViewController, base: Media?, outputUrl: URL) {
        viewController.navigationController?.dismiss(animated: true) {
            let storyboard = UIStoryboard(name: "VideoCapture", bundle: Bundle.main)
            guard let viewController = storyboard.instantiateViewController(withIdentifier: "SaveMediaViewController") as? SaveMediaViewController else {
                fatalError("couldn't instantiate SaveMediaViewController")
            }

            viewController.url = outputUrl
            viewController.base = base
            viewController.delegate = self

            let navigationController = UINavigationController(rootViewController: viewController)
            navigationController.modalPresentationStyle = .overCurrentContext

            self.present(navigationController, animated: true, completion: nil)
        }
    }

    func didCancel(viewController: VideoFiltersViewController) {
        viewController.navigationController?.popViewController(animated: true)
    }
}

extension CreationsViewController: SaveMediaViewControllerDelegate {
    func didConfirm(viewController: SaveMediaViewController, media: Media) {
        viewController.dismiss(animated: true) {
            if let video = media as? Video {
                if video.uuid != nil { // update
                    VideosClient.shared.update(video: video, success: {
                        // no-op
                    }, failure: { error in
                        self.presentErrorDialog(error: error)
                    })
                } else { // create
                    VideosClient.shared.upload(video: video, success: { (_) in
                        // no-op
                    }, failure: { error in
                        self.presentErrorDialog(error: error)
                    })
                }

                return
            }

            if let song = media as? Song {
                if song.uuid != nil { // update
                    SongsClient.shared.update(song: song, success: { song in
                        // no-op
                    }, failure: { error in
                        self.presentErrorDialog(error: error)
                    })
                } else { // create
                    // TODO: implement 2017-11-28 (upload song)
                }
            }
        }
    }

    func didCancel(viewController: SaveMediaViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
}

extension CreationsViewController: MediaPlayerViewControllerDelegate {
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
            let storyboard = UIStoryboard(name: "VideoCapture", bundle: Bundle.main)
            guard let viewController = storyboard.instantiateViewController(withIdentifier: "SaveMediaViewController") as? SaveMediaViewController else {
                fatalError("couldn't instantiate SaveMediaViewController")
            }

            viewController.media = media
            viewController.delegate = self

            let navigationController = UINavigationController(rootViewController: viewController)
            navigationController.modalPresentationStyle = .overCurrentContext

            self.present(navigationController, animated: true, completion: nil)
        })
    }
}
