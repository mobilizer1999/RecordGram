//
//  MediaPreviewViewController.swift
//  RecordGram
//
//  Created by Hugo Prione on 02/11/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import Kingfisher
import AVFoundation
import SCSiriWaveformView

protocol MediaPreviewViewControllerDelegate {
    func didAddVocalsToBeat(viewController: MediaPreviewViewController, media: Media)
    func didLikeMedia()
}

extension MediaPreviewViewControllerDelegate {
    func didLikeMedia() {
        // Do nothing (for now) just makes this optional
    }
}

class MediaPreviewViewController: ModalViewController, ErrorHandler {

    @IBOutlet weak var imgBeat: UIImageView!
    @IBOutlet weak var lblBeatName: UILabel!
    @IBOutlet weak var lblProducerName: UILabel!
    @IBOutlet weak var lblGenre: UILabel!
    @IBOutlet weak var siriWaveForm: SCSiriWaveformView!
    @IBOutlet weak var btnPlay: UIButton!
    @IBOutlet weak var btnLike: UIButton!
    @IBOutlet weak var lblLikes: UILabel!
    @IBOutlet weak var btnDownloadBeat: UIButton!
    @IBOutlet weak var btnAddVocals: UIButton!
    @IBOutlet weak var btnShootVideo: UIButton!
    @IBOutlet weak var sliderProgress: UISlider!

    var media: Media!
    var delegate: MediaPreviewViewControllerDelegate?

    private var player: MediaPlayer?
    private var mediaLikes: [User]? {
        didSet {
            lblLikes?.text = "(\(mediaLikes?.count ?? 0))"
        }
    }
    private var myUuid: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        if let uuid = media?.uuid {
            BeatsClient.shared.view(uuid, success: {

            }, failure: { error in
                self.presentErrorDialog(error: error)
            })
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(true, animated: true)

        // TODO: refactor 2017-11-30 (simplify)
        if let beat = media as? Beat {
            BeatsClient.shared.likes(uuid: beat.uuid ?? "", success: { (users) in
                self.mediaLikes = users
            }, failure: { error in
                self.presentErrorDialog(error: error)
            })
        } else if let song = media as? Song {
            SongsClient.shared.likes(uuid: song.uuid ?? "", success: { (users) in
                self.mediaLikes = users
            }, failure: { error in
                self.presentErrorDialog(error: error)
            })
        } else if let video = media as? Video {
            VideosClient.shared.likes(uuid: video.uuid ?? "", success: { (users) in
                self.mediaLikes = users
            }, failure: { error in
                self.presentErrorDialog(error: error)
            })
        }

        do {
            let localUrl = try FileManager.default.folderPath(forMedia: media)
            let fileExists = FileManager.default.fileExists(atPath: localUrl.path)

            btnDownloadBeat.isHidden = fileExists
            btnAddVocals.isHidden = !fileExists
            btnShootVideo.isHidden = !fileExists

            if fileExists {
                player = MediaPlayer(url: localUrl, withMetering: true)
            } else if let url = media.url {
                player = MediaPlayer(url: url, withMetering: true)
            }

            player?.delegate = self
            btnPlay.isSelected = true
        } catch let error {
            self.presentErrorDialog(error: error)
        }

        lblBeatName.text = media.name

        // TODO: refactor 2017-12-08
        if let song = media as? Song {
            lblProducerName.text = song.beat?.producer?.name ?? NSLocalizedString("Unknown", comment: "Unknown username")
            imgBeat.kf.setImage(with: media.image, placeholder: #imageLiteral(resourceName:"profile_placeholder"), options: nil, progressBlock: nil, completionHandler: nil)
        } else if let video = media as? Video {
            lblProducerName.text = video.beat?.producer?.name ?? NSLocalizedString("Unknown", comment: "Unknown username")
            imgBeat.kf.setImage(with: media.image, placeholder: #imageLiteral(resourceName:"profile_placeholder"), options: nil, progressBlock: nil, completionHandler: nil)
        } else if let beat = media as? Beat {
            if beat.needToPurchase {
                btnDownloadBeat.setTitle(String(format: NSLocalizedString("Unlock for %d Coins", comment: "Unlock beat"), beat.price!), for: .normal)
            }
            lblProducerName.text = beat.producer?.name ?? NSLocalizedString("Unknown", comment: "Unknown username")
            imgBeat.kf.setImage(with: beat.producer?.profilePicture, placeholder: #imageLiteral(resourceName:"profile_placeholder"), options: nil, progressBlock: nil, completionHandler: nil)
        }

        lblGenre.text = media.genre?.name

        setLike(if: media.isLiked)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        player?.stop()
        player = nil
    }

    func downloadMedia() {
        close {
            if let viewController = self.delegate as? UIViewController {
                viewController.download(self.media)
            }
        }
    }

    func didTapProducer(with uuid: String) {
        close {
            if let viewController = self.delegate as? UIViewController {
                viewController.goToProducerProfile(with: uuid)
            }
        }
    }

    func setLike(if isLiked: Bool?) {
        media.isLiked = isLiked
        if let isLiked = isLiked, isLiked {
            btnLike.tintColor = UIColor(hex: "BB1F63")
        } else {
            btnLike.tintColor = UIColor(hex: "FFFFFF")
        }
    }

    @IBAction func didTapProducer(_ sender: Any) {
        if let song = media as? Song, let uuid = song.beat?.producer?.uuid {
            didTapProducer(with: uuid)
        } else if let video = media as? Video, let uuid = video.beat?.producer?.uuid {
            didTapProducer(with: uuid)
        } else if let beat = media as? Beat, let uuid = beat.producer?.uuid {
            didTapProducer(with: uuid)
        }
    }

    @IBAction func sliderProgressValueDidChange(_ sender: Any) {
        player?.pause()
        player?.seek(to: Double(sliderProgress.value), completionHandler: { (_) in
            self.player?.play()
            self.btnPlay.isSelected = true
        })
    }

    @IBAction func didTapPlayPauseButton(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected

        if sender.isSelected {
            player?.play()
        } else {
            player?.pause()
        }
    }

    @IBAction func didTapButtonLike(_ sender: Any) {
        let myUuid = UserClient.shared.uuid()
        let isLiked = mediaLikes?.contains(where: { $0.uuid == myUuid }) ?? false

        if let beat = media as? Beat {
            if !isLiked {
                BeatsClient.shared.like(uuid: beat.uuid ?? "", success: {
                    var me = User()
                    me.uuid = myUuid

                    self.mediaLikes?.append(me)
                    self.delegate?.didLikeMedia()
                    self.setLike(if: true)
                }, failure: { error in
                    self.presentErrorDialog(error: error)
                })
            } else {
                BeatsClient.shared.unlike(uuid: beat.uuid ?? "", success: {
                    if let indexOf = self.mediaLikes?.index(where: { $0.uuid == myUuid }) {
                        self.mediaLikes?.remove(at: indexOf)
                        self.delegate?.didLikeMedia()
                    }
                    self.setLike(if: false)
                }, failure: { error in
                    self.presentErrorDialog(error: error)
                })
            }
        } else if let song = media as? Song {
            if !isLiked {
                SongsClient.shared.like(uuid: song.uuid ?? "", success: {
                    var me = User()
                    me.uuid = myUuid

                    self.mediaLikes?.append(me)
                    self.delegate?.didLikeMedia()
                    self.setLike(if: true)
                }, failure: { error in
                    self.presentErrorDialog(error: error)
                })
            } else {
                SongsClient.shared.unlike(uuid: song.uuid ?? "", success: {
                    if let indexOf = self.mediaLikes?.index(where: { $0.uuid == myUuid }) {
                        self.mediaLikes?.remove(at: indexOf)
                        self.delegate?.didLikeMedia()
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
                    self.delegate?.didLikeMedia()
                    self.setLike(if: true)
                }, failure: { error in
                    self.presentErrorDialog(error: error)
                })
            } else {
                VideosClient.shared.unlike(uuid: video.uuid ?? "", success: {
                    if let indexOf = self.mediaLikes?.index(where: { $0.uuid == myUuid }) {
                        self.mediaLikes?.remove(at: indexOf)
                        self.delegate?.didLikeMedia()
                    }
                    self.setLike(if: false)
                }, failure: { error in
                    self.presentErrorDialog(error: error)
                })
            }
        }
    }

    @IBAction func didTapDownloadBeatButton(_ sender: Any) {
        if let beat = media as? Beat, beat.needToPurchase {
            if beat.canBuy {
                if let uuid = beat.uuid {
                    self.view.loading(with: NSLocalizedString("Making Coins Move!", comment: "Coins"))
                    BeatsClient.shared.purchase(uuid: uuid, success: {
                        UserClient.shared.invalidateUser()
                        UserClient.shared.get("credits") { credits in
                            print("Updated credits:", credits)
                            self.view.loaded()
                            self.downloadMedia()
                        }
                    }, failure: { error in
                        self.view.loaded()
                        print("❗", error.localizedDescription)
                    })
                }
            } else {
                if let viewController = delegate as? UIViewController {
                    close {
                        viewController.openCoinsPopover()
                    }
                }
            }
        } else {
            downloadMedia()
        }
    }

    @IBAction func didTapAddVocalsButton(_ sender: Any) {
        delegate?.didAddVocalsToBeat(viewController: self, media: media)
        close()

    }

    @IBAction func didTapShootVideoButton(_ sender: Any) {
        close {
            if let viewController = self.delegate as? UIViewController {
                viewController.openTrimAudio(for: self.media)
            }
        }
    }
}

extension MediaPreviewViewController: MediaPlayerDelegate {
    func onReadyToPlay(player: MediaPlayer) {
    }

    func onPeriodicTimeObserver(player: MediaPlayer, time: CMTime) {
        let currentTime = Float(time.seconds)
        var duration = Float(player.duration.seconds)

        if duration > 30 {
            duration = 30
        }

        guard currentTime < duration else {
            player.seek(to: 0, completionHandler: { (_) in
                player.play()
            })
            return
        }

        self.sliderProgress.value = currentTime
    }

    func onAveragePower(_ power: CGFloat) {
        self.siriWaveForm.update(withLevel: power)
    }

    func didPlayToEndTime(player: MediaPlayer) {
        player.seek(to: 0, completionHandler: { (_) in
            player.play()
        })
    }

    func didStartPlaying(player: MediaPlayer) {
    }

    func onFailure(error: Error) {
        presentErrorDialog(error: error)
    }
}
