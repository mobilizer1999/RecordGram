//
//  MediaPlayerViewController.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/14/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import CoreMedia
import Photos
import Kingfisher
import FBSDKShareKit

protocol MediaPlayerViewControllerDelegate {
    func didDismiss(viewController: MediaPlayerViewController)
    func didDeleteMedia(viewController: MediaPlayerViewController, media: Media)
    func didUpdateMediaInfo(viewController: MediaPlayerViewController, media: Media)
}

class MediaPlayerViewController: UIViewController, ErrorHandler {
    @IBOutlet var deleteButton: UIBarButtonItem!
    @IBOutlet weak var imgMediaPlaceholder: UIImageView!
    @IBOutlet weak var progressIndicator: UIActivityIndicatorView! {
        didSet {
            progressIndicator.hidesWhenStopped = true
            progressIndicator.startAnimating()
        }
    }
    @IBOutlet weak var btnReport: UIButton! {
        didSet {
            btnReport.isHidden = true
        }
    }
    @IBOutlet weak var imgProfile: RoundImageView!
    @IBOutlet weak var lblUsername: UILabel!
    @IBOutlet weak var lblMediaInfo: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var btnViewsCount: UIButton! {
        didSet {
            btnViewsCount.isUserInteractionEnabled = false
        }
    }
    @IBOutlet weak var btnLikesCount: UIButton!
    @IBOutlet weak var btnCommentsCount: UIButton!
    @IBOutlet weak var btnShare: UIButton!
    @IBOutlet weak var btnMenu: UIButton!
    @IBOutlet weak var btnPlayPause: UIButton! {
        didSet {
            btnPlayPause.isSelected = true
        }
    }
    @IBOutlet weak var sldProgress: UISlider!
    @IBOutlet weak var viewReportMedia: UIView! {
        didSet {
            viewReportMedia.isHidden = true
        }
    }
    @IBOutlet weak var txtReportMessage: UITextView!
    @IBOutlet weak var btnReportAbuse: UIButton!
    @IBOutlet weak var btnReportPorn: UIButton!
    @IBOutlet weak var btnConfirmReport: UIButton!
    @IBOutlet weak var btnCancelReport: UIButton!

    @IBOutlet weak var viewMenu: UIView! {
        didSet {
            viewMenu.isHidden = true
        }
    }
    @IBOutlet weak var btnLoadOriginalMedia: UIButton!
    @IBOutlet weak var btnTogglePublic: UIButton!
    @IBOutlet weak var btnUpdateMediaInfo: UIButton!
    @IBOutlet weak var btnDeleteMedia: UIButton!
    @IBOutlet weak var btnSaveToCameraRoll: UIButton!
    @IBOutlet weak var btnCloseMenu: UIButton!
    @IBOutlet weak var followUnFollowButton: UIButton!

    var media: Media! {
        didSet {
            // TODO: refactor 2017-11-28
            if let _ = media as? Song {
                mediaType = .song
            } else if let _ = media as? Video {
                mediaType = .video
            }
        }
    }
    var delegate: MediaPlayerViewControllerDelegate?

    private var mediaType: MediaType = .song
    private var mediaPlayer: MediaPlayer?
    private var mediaLikes: [User]? {
        didSet {
            btnLikesCount?.setTitle("(\(mediaLikes?.count ?? 0))", for: .normal)
        }
    }
    private var myUuid: String?
    private var isSharingToInstagram: Bool?
    private var isSharingToFacebook: Bool?
    private var isReadyToPlay = false

    override func viewDidLoad() {
        super.viewDidLoad()

        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapView))
        gesture.cancelsTouchesInView = true
        view.addGestureRecognizer(gesture)

        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.backgroundColor = UIColor.black
        navigationController?.setNavigationBarHidden(true, animated: true)

        btnLoadOriginalMedia.isHidden = mediaType == .song
        btnSaveToCameraRoll.isHidden = mediaType == .song

        if media.isPublic == true {
            btnTogglePublic.setTitle(NSLocalizedString("Make Private", comment: "Media privacy"), for: .normal)
        } else {
            btnTogglePublic.setTitle(NSLocalizedString("Add to Community", comment: "Media privacy"), for: .normal)
        }

        switch mediaType {
        case .song:
            btnUpdateMediaInfo.setTitle(NSLocalizedString("Update Song Info", comment: "Update media"), for: .normal)
            btnDeleteMedia.setTitle(NSLocalizedString("Delete Song", comment: "Delete media"), for: .normal)
            btnSaveToCameraRoll.isHidden = true
        case .video:
            btnUpdateMediaInfo.setTitle(NSLocalizedString("Update Video Info", comment: "Update media"), for: .normal)
            btnDeleteMedia.setTitle(NSLocalizedString("Delete Video", comment: "Delete media"), for: .normal)
            btnLoadOriginalMedia.isHidden = true
        }

        if let song = media as? Song {
            SongsClient.shared.get(uuid: song.uuid ?? "", success: { (song) in
                self.media = song

                self.setupLabels()

                guard let url = song.url else {
                    fatalError()
                }

                self.mediaPlayer?.stop()

                self.mediaPlayer = MediaPlayer(url: url)
                self.mediaPlayer?.delegate = self

                SongsClient.shared.likes(uuid: song.uuid ?? "", success: { (users) in
                    self.mediaLikes = users
                }, failure: { error in
                    self.presentErrorDialog(error: error)
                })
            }, failure: { error in
                self.presentErrorDialog(error: error)
            })
        } else if let video = media as? Video {
            VideosClient.shared.get(uuid: video.uuid ?? "", success: { (video) in
                self.media = video

                self.setupLabels()

                guard let url = video.url else {
                    fatalError()
                }

                self.mediaPlayer?.stop()

                self.mediaPlayer = MediaPlayer(url: url)
                self.mediaPlayer?.delegate = self

                let playerView = PlayerView()
                playerView.frame = UIScreen.main.bounds

                self.imgMediaPlaceholder.addSubview(playerView)

                self.mediaPlayer?.playerView = playerView

                if let uuid = video.uuid {
                    VideosClient.shared.likes(uuid: uuid, success: { users in
                        self.mediaLikes = users
                    }, failure: { error in
                        self.presentErrorDialog(error: error)
                    })

                    VideosClient.shared.view(uuid, success: {
                        video.views = (video.views ?? 0) + 1
                    }, failure: { error in
                        self.presentErrorDialog(error: error)
                    })
                }
            }, failure: { error in
                self.presentErrorDialog(error: error)
            })
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // TODO: 2018-05-02 refactor use auto layout
        UIView.animate(withDuration: 0.25, animations: {
            self.imgMediaPlaceholder.subviews.forEach { (view) in
                view.frame = self.imgMediaPlaceholder.frame
            }
        })
    }

    override func viewWillAppear(_ animated: Bool) {
        setupLabels()

        super.viewWillAppear(animated)

        if isReadyToPlay, btnPlayPause.isSelected {
            mediaPlayer?.play()
        }

        UIApplication.shared.isStatusBarHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        mediaPlayer?.autoPlay = false
        mediaPlayer?.stop()
        mediaPlayer = nil

        UIApplication.shared.isStatusBarHidden = false
    }

    @objc func didTapView(_ gesture: UIGestureRecognizer) {
        guard gesture.state == .ended else {
            return
        }

        if viewReportMedia.alpha > 0 {
            closeViewReport()
            return
        }

        if viewMenu.alpha > 0 {
            closeViewMenu()
            return
        }

        didTapPlayPauseButton(btnPlayPause)
    }

    func closeViewMenu() {
        UIView.animate(withDuration: 0.25, animations: {
            self.viewMenu.alpha = 0
        }, completion: { _ in
            self.viewMenu.isHidden = true
        })
    }

    func closeViewReport() {
        UIView.animate(withDuration: 0.25, animations: {
            self.viewReportMedia.alpha = 0
        }, completion: { _ in
            self.viewReportMedia.isHidden = true
        })
    }

    func showVideoEditor() {
        var urlCropped: URL!
        do {
            urlCropped = try FileManager.default.tempFolderPathCropped(forMedia: media)
        } catch let error {
            self.presentErrorDialog(error: error)
            return
        }

        var url: URL!
        do {
            url = try FileManager.default.folderPath(forMedia: media)
        } catch let error {
            self.presentErrorDialog(error: error)
            return
        }

        let asset = AVAsset(url: url)

        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            return
        }

        let naturalSize = videoTrack.naturalSize
        let size = max(naturalSize.width, naturalSize.height)

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: kCMTimeZero, duration: kCMTimePositiveInfinity)

        let rgb = CGColorSpaceCreateDeviceRGB()
        let white: [CGFloat] = [1.0, 1.0, 1.0, 1.0] // white
        let color = CGColor(colorSpace: rgb, components: white)
        instruction.backgroundColor = color

        let transform = videoTrack.preferredTransform.translatedBy(x: (size - naturalSize.width) / 2, y: (size - naturalSize.height) / 2)
        let layerInstructions = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)

        layerInstructions.setTransform(transform, at: kCMTimeZero)
        instruction.layerInstructions = [layerInstructions]

        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = CGSize(width: size, height: size)
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.instructions = [instruction]

        guard videoComposition.isValid(for: asset, timeRange: CMTimeRange(start: kCMTimeZero, duration: kCMTimePositiveInfinity), validationDelegate: nil) else {
            return
        }
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            return
        }
        exportSession.videoComposition = videoComposition
        exportSession.outputURL = urlCropped
        exportSession.outputFileType = .mp4
        exportSession.exportAsynchronously(completionHandler: {
            DispatchQueue.main.async {
                switch exportSession.status {
                case .completed:
                    let viewController = UIVideoEditorController()
                    viewController.videoPath = urlCropped.path
                    viewController.delegate = self
                    viewController.videoQuality = .typeHigh

                    self.present(viewController, animated: true, completion: nil)
                case .failed, .cancelled:
                    guard let error = exportSession.error else {
                        return
                    }
                    self.presentErrorDialog(error: error)
                default:
                    break
                }
            }
        })
    }

    func setupLabels() {
        imgProfile.kf.setImage(with: media.user?.picture, placeholder: #imageLiteral(resourceName:"user_placeholder"), options: nil, progressBlock: nil, completionHandler: nil)
        lblUsername.text = "@\(media.user?.username ?? media.user?.name ?? NSLocalizedString("Unknown", comment: "Unknown username"))"
        
        if let description = media.description, !description.isEmpty {
            descriptionLabel.isHidden = false
            descriptionLabel.text = description
        } else {
            descriptionLabel.isHidden = true
        }
        
        if media.amOwner {
            navigationItem.setRightBarButton(deleteButton, animated: false)
        } else {
            navigationItem.setRightBarButton(nil, animated: false)
        }

        setLike(if: media.isLiked)

        if !media.amOwner {
            btnMenu.isHidden = true
        }

        followUnFollowButton.isSelected = media.user?.amFollowing ?? false

        btnCommentsCount.setTitle("(\(media?.comments ?? 0))", for: .normal)
        btnViewsCount.setTitle("(\(media?.views ?? 0))", for: .normal)

        // TODO: refactor 2017-12-08
        if let song = media as? Song {
            lblMediaInfo.text = String(format: NSLocalizedString("%@ produced by %@", comment: "Media produced by"), (song.name ?? "").uppercased(), (song.beat?.producer?.name ?? NSLocalizedString("Unknown", comment: "Unknown username")).uppercased())

            self.imgMediaPlaceholder.kf.setImage(with: song.thumbnail, placeholder: #imageLiteral(resourceName:"media_placeholder"))
        } else if let video = media as? Video {
            lblMediaInfo.text = String(format: NSLocalizedString("%@ produced by %@", comment: "Media produced by"), (video.name ?? "").uppercased(), (video.beat?.producer?.name ?? NSLocalizedString("Unknown", comment: "Unknown username")).uppercased())
        } else if let beat = media as? Beat {
            lblMediaInfo.text = String(format: NSLocalizedString("%@ produced by %@", comment: "Media produced by"), (beat.name ?? "").uppercased(), (beat.producer?.name ?? NSLocalizedString("Unknown", comment: "Unknown username")).uppercased())
        }
    }

    func setLike(if isLiked: Bool?) {
        media.isLiked = isLiked
        if let isLiked = isLiked, isLiked {
            btnLikesCount.tintColor = UIColor(hex: "BB1F63")
        } else {
            btnLikesCount.tintColor = UIColor(hex: "FFFFFF")
        }
    }

    // MARK: - IBActions

    @IBAction func didTapProfile(_ sender: Any) {
        if let uuid = media.user?.uuid {
            if let arUser = media.user?.isANR {
                goToProfile(uuid: uuid, arUser: arUser)
            } else {
                goToProfile(uuid: uuid)
            }
        }
    }

    @IBAction func didTapProducer(_ sender: Any) {
        if let song = media as? Song {
            if let uuid = song.beat?.producer?.uuid {
                goToProducerProfile(with: uuid)
            }
        } else if let video = media as? Video {
            if let uuid = video.beat?.producer?.uuid {
                goToProducerProfile(with: uuid)
            }
        } else if let beat = media as? Beat {
            if let uuid = beat.producer?.uuid {
                goToProducerProfile(with: uuid)
            }
        }
    }

    @IBAction func didTapCloseButton(_ sender: Any) {
        mediaPlayer?.stop()
        mediaPlayer = nil

        delegate?.didDismiss(viewController: self)
    }

    @IBAction func didTapDeleteMediaButton(_ sender: Any) {
        // TODO: refactor 2017-12-01 (simplify)
        if let song = media as? Song {
            SongsClient.shared.delete(uuid: song.uuid ?? "", success: {
                self.delegate?.didDeleteMedia(viewController: self, media: self.media)
            }, failure: { error in
                self.presentErrorDialog(error: error)
            })
        } else if let video = media as? Video {
            VideosClient.shared.delete(uuid: video.uuid ?? "", success: {
                self.delegate?.didDeleteMedia(viewController: self, media: self.media)
            }, failure: { error in
                self.presentErrorDialog(error: error)
            })
        }
    }

    // TODO: refactor 2017-11-30 (simplify)
    @IBAction func didTapLikeMediaButton(_ sender: Any) {
        let myUuid = UserClient.shared.uuid()
        let isLiked = mediaLikes?.contains(where: { $0.uuid == myUuid }) ?? false

        if let song = media as? Song {
            if !isLiked {
                SongsClient.shared.like(uuid: song.uuid ?? "", success: {
                    var me = User()
                    me.uuid = myUuid

                    self.mediaLikes?.append(me)
                    self.setLike(if: true)
                }, failure: { error in
                    self.presentErrorDialog(error: error)
                })
            } else {
                SongsClient.shared.unlike(uuid: song.uuid ?? "", success: {
                    if let indexOf = self.mediaLikes?.index(where: { $0.uuid == myUuid }) {
                        self.mediaLikes?.remove(at: indexOf)
                    }
                    self.setLike(if: false)
                }, failure: { error in
                    self.presentErrorDialog(error: error)
                })
            }
        } else if let video = media as? Video {
            if !isLiked {
                VideosClient.shared.like(uuid: video.uuid ?? "", success: {
                    var me = User()
                    me.uuid = myUuid

                    self.mediaLikes?.append(me)
                    self.setLike(if: true)
                }, failure: { error in
                    self.presentErrorDialog(error: error)
                })
            } else {
                VideosClient.shared.unlike(uuid: video.uuid ?? "", success: {
                    if let indexOf = self.mediaLikes?.index(where: { $0.uuid == myUuid }) {
                        self.mediaLikes?.remove(at: indexOf)
                    }
                    self.setLike(if: false)
                }, failure: { error in
                    self.presentErrorDialog(error: error)
                })
            }
        }
    }

    @IBAction func didTapCommentsButton(_ sender: Any) {
        openComments(with: media)
    }

    @IBAction func didTapShareButton(_ sender: UIButton) {
        guard let uuid = media.uuid else {
            fatalError()
        }
        
        let url = "http://view.cre8tor.app/\(uuid)"
        let message = String(format: NSLocalizedString("Check this out. It was made on @Cre8tor by %@.", comment: "Share"), media.user?.toString() ?? NSLocalizedString("Unknown", comment: "Unknown user"))
        
        var activities = [UIActivity]()
        if let _ = media as? Video {
            let instagramActivity = InstagramActivity()
            instagramActivity.delegate = self

            let facebookActivity = FacebookActivity()
            facebookActivity.delegate = self

            activities.append(instagramActivity)
            activities.append(facebookActivity)
        }

        let activityController = UIActivityViewController(activityItems: [message, url], applicationActivities: activities)
        activityController.popoverPresentationController?.sourceView = sender
        activityController.popoverPresentationController?.sourceRect = sender.frame

        present(activityController, animated: true, completion: nil)
    }

    @IBAction func didTapMenuButton(_ sender: Any) {
        viewMenu.isHidden = false
        viewMenu.alpha = 0

        UIView.animate(withDuration: 0.25, animations: {
            self.viewMenu.alpha = 1
        })
    }

    @IBAction func didTapPlayPauseButton(_ sender: Any) {
        btnPlayPause.isSelected = !btnPlayPause.isSelected

        if btnPlayPause.isSelected {
            mediaPlayer?.play()
            btnReport.isHidden = true
            navigationController?.setNavigationBarHidden(true, animated: true)
        } else {
            mediaPlayer?.pause()
            btnReport.isHidden = false
            navigationController?.setNavigationBarHidden(false, animated: true)
        }
    }

    @IBAction func sldProgressValueChanged(_ sender: Any) {
        mediaPlayer?.pause()
        mediaPlayer?.seek(to: Double(sldProgress.value), completionHandler: { (_) in
            // no-op
        })
    }

    @IBAction func didTapReportButton(_ sender: UIButton) {
        let viewController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        viewController.popoverPresentationController?.sourceView = sender
        viewController.popoverPresentationController?.sourceRect = sender.frame

        viewController.addAction(UIAlertAction(title: NSLocalizedString("Block this User", comment: "Dialog option"), style: .destructive, handler: { _ in
            self.presentBlockUserDialog(sender)
        }))

        var title = ""
        switch mediaType {
        case .song:
            title = NSLocalizedString("Report this song", comment: "Dialog option")
        case .video:
            title = NSLocalizedString("Report this song", comment: "Dialog option")
        }
        viewController.addAction(UIAlertAction(title: title, style: .destructive, handler: { _ in
            // TODO: implement 2017-11-30 ()
        }))
        viewController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Dialog option"), style: .cancel, handler: nil))

        self.present(viewController, animated: true, completion: nil)
    }

    private func presentBlockUserDialog(_ sender: UIButton) {
        let username = media.user?.username ?? NSLocalizedString("Unknown", comment: "Unknown username")
        let title = String(format: NSLocalizedString("Are you sure you want to block %@?", comment: "Dialog title"), username)
        let message = String(format: NSLocalizedString("If you block, you will not see any post from %@", comment: "Dialog message"), username)

        let viewController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        viewController.popoverPresentationController?.sourceView = sender
        viewController.popoverPresentationController?.sourceRect = sender.frame

        viewController.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: "Dialog option"), style: .destructive, handler: { _ in
            // TODO: implement 2017-11-30 ()
        }))
        viewController.addAction(UIAlertAction(title: NSLocalizedString("No", comment: "Dialog option"), style: .cancel, handler: nil))

        self.present(viewController, animated: true, completion: nil)
    }

    @IBAction func didTapReportAbuseButton(_ sender: Any) {
        btnReportAbuse.isSelected = true
        btnReportPorn.isSelected = false
    }

    @IBAction func didTapReportPornButton(_ sender: Any) {
        btnReportPorn.isSelected = true
        btnReportAbuse.isSelected = false
    }

    @IBAction func didTapConfirmReportButton(_ sender: Any) {
    }

    @IBAction func didTapCancelReportButton(_ sender: Any) {
        UIView.animate(withDuration: 0.25, animations: {
            self.viewReportMedia.alpha = 0
        }, completion: { _ in
            self.viewReportMedia.isHidden = true
        })
    }

    @IBAction func didTapLoadOriginalMediaButton(_ sender: Any) {
        // TODO: implement 2017-11-30 ()
    }

    @IBAction func didTapTogglePublicButton(_ sender: Any) {
        if let song = media as? Song {
            song.isPublic = !(song.isPublic ?? false)

            SongsClient.shared.update(song: song, success: { song in
                if song.isPublic == true {
                    self.btnTogglePublic.setTitle(NSLocalizedString("Make Private", comment: "Media privacy"), for: .normal)
                } else {
                    self.btnTogglePublic.setTitle(NSLocalizedString("Add to Community", comment: "Media privacy"), for: .normal)
                }

                self.closeViewMenu()
            }, failure: { error in
                self.presentErrorDialog(error: error)
            })
        } else if let video = media as? Video {
            video.isPublic = !(video.isPublic ?? false)

            VideosClient.shared.update(video: video, success: {
                if video.isPublic == true {
                    self.btnTogglePublic.setTitle(NSLocalizedString("Make Private", comment: "Media privacy"), for: .normal)
                } else {
                    self.btnTogglePublic.setTitle(NSLocalizedString("Add to Community", comment: "Media privacy"), for: .normal)
                }

                self.closeViewMenu()
            }, failure: { error in
                self.presentErrorDialog(error: error)
            })
        }
    }

    @IBAction func didTapUpdateMediaInfoButton(_ sender: Any) {
        delegate?.didUpdateMediaInfo(viewController: self, media: media)
    }

    @IBAction func didTapSaveToCameraRollButton(_ sender: Any) {
        isSharingToInstagram = false
        isSharingToFacebook = false // FIXME: 2017-12-07 use enum

        var url: URL!
        do {
            url = try FileManager.default.folderPath(forMedia: self.media)
        } catch let error {
            self.presentErrorDialog(error: error)
            return
        }

        if !FileManager.default.fileExists(atPath: url.path) {
            let storyboard = UIStoryboard(name: "ARUser", bundle: Bundle.main)
            guard let viewController = storyboard.instantiateViewController(withIdentifier: "MediaDownloaderViewController") as? MediaDownloaderViewController else {
                fatalError("couldn't instantiate MediaDownloaderViewController")
            }

            viewController.media = media
            viewController.delegate = self

            let navigationController = UINavigationController(rootViewController: viewController)
            navigationController.modalPresentationStyle = .overFullScreen

            self.present(navigationController, animated: true, completion: nil)

            return
        }

        PHPhotoLibrary.requestAuthorization({ status in
            switch status {// TODO: implement 2017-12-07 other states
            case .notDetermined:
                break;
            case .restricted:
                break;
            case .denied:
                break;
            case .authorized:
                var url: URL!

                do {
                    url = try FileManager.default.folderPath(forMedia: self.media)
                } catch let error {
                    self.presentErrorDialog(error: error)

                    return
                }

                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                }, completionHandler: { success, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            self.presentErrorDialog(error: error)
                            return
                        }

                        if !success {
                            self.view.makeToast(NSLocalizedString("Video Saving Failed", comment: "Error message"), duration: 3, position: .center)
                            return
                        }

                        self.closeViewMenu()
                        self.view.makeToast(NSLocalizedString("Video Saved", comment: "Success message"), duration: 3, position: .center)
                    }
                })
            }
        })
    }

    @IBAction func didTapCloseMenuButton(_ sender: Any) {
        closeViewMenu()
    }

    @IBAction func didTapFollowUnFollowButton() {
        if let amFollowing = media.user?.amFollowing, let uuid = media.user?.uuid {
            if amFollowing {
                UserClient.shared.unFollow(uuid: uuid, success: {
                    self.media.user?.amFollowing = false
                    self.followUnFollowButton.isSelected = true
                }, failure: { error in })
            } else {
                UserClient.shared.follow(uuid: uuid, success: {
                    self.media.user?.amFollowing = true
                    self.followUnFollowButton.isSelected = false
                }, failure: { error in })
            }
        }
    }
}

extension MediaPlayerViewController: MediaPlayerDelegate {

    func onReadyToPlay(player: MediaPlayer) {
        progressIndicator.stopAnimating()

        isReadyToPlay = true
        if !CMTIME_IS_INDEFINITE(player.duration) {
            sldProgress.maximumValue = Float(player.duration.seconds)
        }
    }

    func onPeriodicTimeObserver(player: MediaPlayer, time: CMTime) {
        sldProgress.setValue(Float(time.seconds), animated: true)
    }

    func didPlayToEndTime(player: MediaPlayer) {
        player.seek(to: 0) { (_) in
            player.play()
        }
    }

    func didStartPlaying(player: MediaPlayer) {
    }

    func onFailure(error: Error) {
        self.presentErrorDialog(error: error)
    }
}

extension MediaPlayerViewController: MediaDownloaderViewControllerDelegate {

    func didDownloadMedia(viewController: MediaDownloaderViewController, media: Media, url: URL) {
        viewController.close {
            if self.isSharingToInstagram == true || self.isSharingToFacebook == true {
                self.showVideoEditor()
                return
            }

            self.didTapSaveToCameraRollButton(self.btnSaveToCameraRoll)
        }
    }
}

extension MediaPlayerViewController: CustomActivityDelegate {// TODO: refactor 2017-12-07
    func prepare(activity: UIActivity, withActivityItems activityItems: [Any]) {
        var url: URL!
        do {
            url = try FileManager.default.folderPath(forMedia: media)
        } catch let error {
            self.presentErrorDialog(error: error)
            return
        }

        isSharingToInstagram = activity.isKind(of: InstagramActivity.self)
        isSharingToFacebook = activity.isKind(of: FacebookActivity.self)

        if FileManager.default.fileExists(atPath: url.path) {
            if isSharingToInstagram == true || isSharingToFacebook == true {
                showVideoEditor()
                return
            }
        }

        DispatchQueue.main.async {
            let storyboard = UIStoryboard(name: "ARUser", bundle: Bundle.main)
            guard let viewController = storyboard.instantiateViewController(withIdentifier: "MediaDownloaderViewController") as? MediaDownloaderViewController else {
                fatalError("couldn't instantiate MediaDownloaderViewController")
            }

            viewController.media = self.media
            viewController.delegate = self

            let navigationController = UINavigationController(rootViewController: viewController)
            navigationController.modalPresentationStyle = .overFullScreen

            self.present(navigationController, animated: true, completion: nil)
        }
    }
}

extension MediaPlayerViewController: UIVideoEditorControllerDelegate, UINavigationControllerDelegate {
    func videoEditorControllerDidCancel(_ editor: UIVideoEditorController) {
        editor.dismiss(animated: true, completion: nil)
    }

    func videoEditorController(_ editor: UIVideoEditorController, didFailWithError error: Error) {
        editor.dismiss(animated: true) {
            self.presentErrorDialog(error: error)
        }
    }

    func videoEditorController(_ editor: UIVideoEditorController, didSaveEditedVideoToPath editedVideoPath: String) {
        editor.dismiss(animated: true) {
            guard let url = URL(string: editedVideoPath) else {
                return
            }

            PHPhotoLibrary.requestAuthorization({ status in
                switch status {// TODO: implement 2017-12-07 other states
                case .notDetermined:
                    break;
                case .restricted:
                    break;
                case .denied:
                    break;
                case .authorized:
                    var localIdentifier: String?

                    PHPhotoLibrary.shared().performChanges({
                        let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)

                        localIdentifier = request?.placeholderForCreatedAsset?.localIdentifier
                    }, completionHandler: { success, error in
                        DispatchQueue.main.async {
                            if let error = error {
                                self.presentErrorDialog(error: error)
                                return
                            }

                            if !success {
                                self.view.makeToast(NSLocalizedString("Video Saving Failed", comment: "Error message"), duration: 3, position: .center)
                                return
                            }

                            // TODO: refactor 2017-12-08
                            if self.isSharingToInstagram == true {
                                guard let urlInstagram = URL(string: "instagram://library?AssetPath=\(editedVideoPath.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)") else {
                                    return
                                }
                                let application = UIApplication.shared

                                if application.canOpenURL(urlInstagram) {
                                    application.open(urlInstagram, options: [:], completionHandler: nil)
                                } else {
                                    self.view.makeToast(NSLocalizedString("Instagram App is not available in your device, please install it first.", comment: "Error message"), duration: 3, position: .center)
                                }

                                return
                            }

                            // TODO: refactor 2017-12-08
                            if self.isSharingToFacebook == true {
                                guard let localIdentifier = localIdentifier else {
                                    return
                                }

                                let assetIdentifier = localIdentifier.replacingOccurrences(of: "/.*", with: "", options: .regularExpression, range: nil)
                                let urlAssetString = "assets-library://asset/asset.MOV?id=\(assetIdentifier)&ext=MOV"
                                let shareVideo = FBSDKShareVideo(videoURL: URL(string: urlAssetString))
                                let shareVideoContent = FBSDKShareVideoContent()

                                shareVideoContent.video = shareVideo

                                let dialog = FBSDKShareDialog()
                                dialog.shareContent = shareVideoContent
                                dialog.show()

                                return
                            }
                        }
                    })
                }
            })
        }
    }
}
