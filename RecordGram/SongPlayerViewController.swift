//
//  SongPlayerViewController.swift
//  RecordGram
//
//  Created by Nicolas Gonzalez on 4/10/18.
//  Copyright © 2018 Meridian Inc. All rights reserved.
//

import UIKit
import AVFoundation
import SCSiriWaveformView

class SongPlayerViewController: ModalViewController, ErrorHandler {

    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var nameLabel: UIButton!
    @IBOutlet weak var producerLabel: UIButton!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var progressSlider: UISlider!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var recordVideoButton: UIButton!
    @IBOutlet weak var viewsButton: UIButton!
    @IBOutlet weak var commentsButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var publicPrivateButton: UIButton!
    @IBOutlet weak var menuView: UIVisualEffectView!
    @IBOutlet weak var siriWaveForm: SCSiriWaveformView!
    
    var song: Song?
    var delegate: UIViewController?

    private let mediaPlaceholder = #imageLiteral(resourceName:"media_placeholder")
    private let profilePlaceholder = #imageLiteral(resourceName:"profile_placeholder")
    private var player: MediaPlayer?
    private var isReadyToPlay = false

    private var action = Action.shootVideo

    override func viewDidLoad() {
        super.viewDidLoad()

        if let uuid = song?.uuid {
            SongsClient.shared.get(uuid: uuid, success: { song in
                self.song = song
                self.setup()
                SongsClient.shared.view(uuid, success: {
                    song.views = (song.views ?? 0) + 1
                }, failure: { error in
                    self.presentErrorDialog(error: error)
                })
            }, failure: { error in
                self.presentErrorDialog(error: error)
            })
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        setup()

        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(true, animated: true)

        if isReadyToPlay, playPauseButton.isSelected {
            player?.play()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        player?.autoPlay = false
        player?.pause()
    }

    override func close(_ completion: (() -> Void)? = nil) {
        player?.stop()
        player = nil
        super.close(completion)
    }



    func setup() {
        if let url = song?.url, player == nil {
            // TODO: Add play from file if file exists.
            player = MediaPlayer(url: url, withMetering: true)
            player?.delegate = self
        }

        titleLabel.text = song?.name ?? ""
        nameLabel.setTitle(song?.user?.username ?? song?.user?.name, for: .normal)
        producerLabel.setTitle(song?.beat?.producer?.name, for: .normal)
        commentsButton.setTitle("(\(song?.comments ?? 0))", for: .normal)
        viewsButton.setTitle("(\(song?.views ?? 0))", for: .normal)

        setLike(if: song?.isLiked)

        publicPrivateButton.isSelected = song?.isPublic ?? false

        if song?.amOwner ?? false {
            likeButton.isHidden = true
        } else {
            editButton.isHidden = true
            recordVideoButton.isHidden = true
        }

        thumbnailImageView.layer.cornerRadius = 4
        if let thumbnail = song?.thumbnail {
            thumbnailImageView.kf.setImage(with: thumbnail, placeholder: mediaPlaceholder)
        } else if let profilePicture = song?.user?.picture {
            thumbnailImageView.kf.setImage(with: profilePicture, placeholder: profilePlaceholder)
            thumbnailImageView.layer.cornerRadius = 129
        } else {
            thumbnailImageView.image = mediaPlaceholder
        }
    }

    func setLike(if isLiked: Bool?) {
        song?.isLiked = isLiked
        if let isLiked = isLiked, isLiked {
            likeButton.tintColor = UIColor(hex: "BB1F63")
        } else {
            likeButton.tintColor = UIColor(hex: "FFFFFF")
        }
    }

    func closeMenu(_ completion: (() -> Void)? = nil) {
        menuView.popOut { _ in
            self.menuView.isHidden = true
            completion?()
        }
    }

    func creations(with mode: Mode) {
        guard let tabBarController = self.delegate?.tabBarController else {
            return
        }
        //Go to creations tab
        tabBarController.selectedIndex = 3

        // TODO: 2018-02-07 refactor find better way
        guard let creationsViewController = (tabBarController.viewControllers?[3] as? UINavigationController)?.viewControllers.first as? CreationsViewController else {
            return
        }
        creationsViewController.mode = mode
        creationsViewController.loadMedia()
    }
    
    @IBAction func didTapPlayPauseButton() {
        playPauseButton.isSelected = !playPauseButton.isSelected

        if playPauseButton.isSelected {
            player?.play()
        } else {
            player?.pause()
        }
    }

    @IBAction func didTapUser() {
        if let uuid = song?.user?.uuid {
            if let arUser = song?.user?.isANR {
                goToProfile(uuid: uuid, arUser: arUser)
            } else {
                goToProfile(uuid: uuid)
            }
        }
    }

    @IBAction func didTapProducer() {
        if let uuid = song?.beat?.producer?.uuid {
            goToProducerProfile(with: uuid)
        }
    }

    @IBAction func didTapLikeMediaButton() {
        if song?.isLiked ?? false {
            SongsClient.shared.unlike(uuid: song?.uuid ?? "", success: {
                self.setLike(if: false)
            }, failure: { error in
                self.presentErrorDialog(error: error)
            })
        } else {
            SongsClient.shared.like(uuid: song?.uuid ?? "", success: {
                self.setLike(if: true)
            }, failure: { error in
                self.presentErrorDialog(error: error)
            })
        }
    }

    @IBAction func didTapRecordVideoButton() {
        closeMenu {
            self.close {
                if let song = self.song {
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

                        self.delegate?.present(navigationController, animated: true, completion: nil)
                        return
                    }

                    let storyboard = UIStoryboard(name: "ARUser", bundle: Bundle.main)
                    guard let viewController = storyboard.instantiateViewController(withIdentifier: "TrimAudioViewController") as? TrimAudioViewController else {
                        fatalError("couldn't instantiate TrimAudioViewController")
                    }

                    viewController.media = song
                    viewController.delegate = self

                    self.delegate?.present(viewController, animated: true, completion: nil)
                }
            }
        }
    }

    @IBAction func didTapShareButton(_ sender: UIButton) {
        guard let uuid = song?.uuid else {
            fatalError()
        }

        let url = "http://view.cre8tor.app/\(uuid)"
        let username = song?.user?.toString() ?? NSLocalizedString("Unknown", comment: "Unknown username")
        let message = String(format: NSLocalizedString("Check this out. It was made on @Cre8tor by %@.", comment: "Share"), username)

        let activityController = UIActivityViewController(activityItems: [message, url], applicationActivities: [])
        activityController.popoverPresentationController?.sourceView = sender
        activityController.popoverPresentationController?.sourceRect = sender.frame

        present(activityController, animated: true)
    }

    @IBAction func didTapCommentsButton(_ sender: Any) {
        openComments(with: song)
    }

    @IBAction func progressSliderValueChanged() {
        player?.pause()
        player?.seek(to: Double(progressSlider.value)) { _ in
            self.player?.play()
            self.playPauseButton.isSelected = true
        }
    }

    @IBAction func didTapEditButton() {
        menuView.popIn()
    }

    @IBAction func didTapPublicPrivateButton() {
        if let song = song {
            song.isPublic = !(song.isPublic ?? false)
            SongsClient.shared.update(song: song, success: { song in
                self.song = song
                self.publicPrivateButton.isSelected = song.isPublic ?? false
            }, failure: { error in
                self.presentErrorDialog(error: error)
            })
        }
    }

    @IBAction func didTapUpdateSongInfoButton() {
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

    @IBAction func didTapAddMoreVocalsButton() {
        closeMenu {
            self.close {
                if let song = self.song {
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

                        viewController.media = self.song
                        viewController.delegate = self

                        let navigationController = UINavigationController(rootViewController: viewController)
                        navigationController.modalPresentationStyle = .overFullScreen

                        self.delegate?.present(navigationController, animated: true, completion: nil)
                        return
                    }

                    // TODO: 2018-01-02 refactor find better way
                    guard let tabBarController = self.delegate?.tabBarController else {
                        return
                    }

                    guard let navigationController = tabBarController.viewControllers?[2] as? UINavigationController else {
                        return
                    }
                    guard let studioViewController = navigationController.viewControllers.first as? StudioViewController else {
                        return
                    }
                    navigationController.popToRootViewController(animated: false)
                    tabBarController.selectedIndex = 2
                    DispatchQueue.main.async {
                        studioViewController.media = song
                    }
                }
            }
        }
    }

    @IBAction func didTapDeleteSongButton() {
        closeMenu {
            self.close {
                guard let uuid = self.song?.uuid else {
                    return
                }
                SongsClient.shared.delete(uuid: uuid, success: {

                }, failure: { error in
                    self.presentErrorDialog(error: error)
                })
            }
        }
    }

    @IBAction func didTapCloseMenuButton() {
        closeMenu()
    }
}

extension SongPlayerViewController: MediaPlayerDelegate {

    func onReadyToPlay(player: MediaPlayer) {
        isReadyToPlay = true
        
        if !CMTIME_IS_INDEFINITE(player.duration) {
            progressSlider.maximumValue = Float(player.duration.seconds)
        }
    }

    func onPeriodicTimeObserver(player: MediaPlayer, time: CMTime) {
        progressSlider.value = Float(time.seconds)
    }

    func didPlayToEndTime(player: MediaPlayer) {
        player.seek(to: 0) { _ in
            player.play()
        }
    }

    func didStartPlaying(player: MediaPlayer) {
    }

    func onFailure(error: Error) {
        presentErrorDialog(error: error)
    }
    
    func onAveragePower(_ power: CGFloat) {
        siriWaveForm.update(withLevel: power)
    }
}

extension SongPlayerViewController: SaveMediaViewControllerDelegate {

    func didConfirm(viewController: SaveMediaViewController, media: Media) {
        viewController.dismiss(animated: true) {
            if let song = media as? Song {
                if song.uuid != nil {
                    SongsClient.shared.update(song: song, success: { song in
                        self.song = song
                        self.setup()
                        self.creations(with: .song)
                    }, failure: { error in
                        self.presentErrorDialog(error: error)
                    })
                }
            }
            if let video = media as? Video {
                if video.uuid != nil { // update
                    // I don't think this would ever happen
                    VideosClient.shared.update(video: video, success: {
                        self.creations(with: .video)
                    }, failure: { error in
                        self.presentErrorDialog(error: error)
                    })
                } else { // create
                    self.delegate?.view.loading(with: NSLocalizedString("Looks good! Let us Save it Now!", comment: "Song recording"))
                    VideosClient.shared.upload(video: video, success: { (_) in
                        self.delegate?.view.loaded()
                        self.creations(with: .video)
                    }, failure: { error in
                        self.presentErrorDialog(error: error)
                    })
                }

                return
            }
        }
    }

    func didCancel(viewController: SaveMediaViewController) {
        viewController.dismiss(animated: true)
    }
}

extension SongPlayerViewController: MediaDownloaderViewControllerDelegate {

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

                self.delegate?.present(viewController, animated: true, completion: nil)
            case .addVocals:
                guard let tabBarController = self.delegate?.tabBarController else {
                    return
                }

                guard let navigationController = tabBarController.viewControllers?[2] as? UINavigationController else {
                    return
                }
                guard let studioViewController = navigationController.viewControllers.first as? StudioViewController else {
                    return
                }
                navigationController.popToRootViewController(animated: false)
                tabBarController.selectedIndex = 2
                DispatchQueue.main.async {
                    studioViewController.media = media
                }
            }
        }
    }
}

extension SongPlayerViewController: TrimAudioViewControllerDelegate {
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

            self.delegate?.present(navigationController, animated: true, completion: nil)
        }
    }
}

extension SongPlayerViewController: CaptureVideoViewControllerDelegate {
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

extension SongPlayerViewController: VideoFiltersViewControllerDelegate {
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

            self.delegate?.present(navigationController, animated: true, completion: nil)
        }
    }

    func didCancel(viewController: VideoFiltersViewController) {
        viewController.navigationController?.popViewController(animated: true)
    }
}

extension UIViewController {

    func play(_ song: Song) {
        let storyboard = UIStoryboard(name: "Players", bundle: Bundle.main)

        guard let viewController = storyboard.instantiateViewController(withIdentifier: "SongPlayerViewController") as? SongPlayerViewController else {
            fatalError("couldn't instantiate MediaPlayerViewController")
        }

        viewController.song = song
        viewController.delegate = self

        let navigationController = UINavigationController(rootViewController: viewController)

        navigationController.modalPresentationStyle = .overFullScreen

        self.present(navigationController, animated: true)
    }
}
