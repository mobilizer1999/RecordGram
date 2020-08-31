//
//  TrimAudioViewController.swift
//  RecordGram
//
//  Created by Hugo Prione on 13/11/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import MediaPlayer

protocol TrimAudioViewControllerDelegate {
    func didDismiss(viewController: TrimAudioViewController)
    func didTrimMedia(viewController: TrimAudioViewController, media: Media, output: URL)
}

class TrimAudioViewController: UIViewController, ErrorHandler {

    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var lblSongTitle: UILabel!
    @IBOutlet weak var lblProducerName: UILabel!
    @IBOutlet weak var btnPlay: UIButton!
    @IBOutlet weak var btnConfirm: UIButton!
    @IBOutlet weak var lblStartTime: UILabel!
    @IBOutlet weak var lblTrimStartTime: UILabel!
    @IBOutlet weak var lblTrimStartTimeLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var sliderStartTime: UISlider!
    @IBOutlet weak var lblEndTime: UILabel!
    @IBOutlet weak var viewVolume: MPVolumeView! {
        didSet {
            viewVolume.showsRouteButton = false
            viewVolume.tintColor = UIColor.primary
            viewVolume.setVolumeThumbImage(#imageLiteral(resourceName:"progress_thumb_medium"), for: .normal)
            if let slider = viewVolume.subviews.filter({ $0.isKind(of: UISlider.self) }).first as? UISlider {
                slider.minimumValueImage = #imageLiteral(resourceName:"volume_down").withRenderingMode(.alwaysTemplate)
                slider.maximumValueImage = #imageLiteral(resourceName:"volume_up").withRenderingMode(.alwaysTemplate)
            }
            viewVolume.tintColor = UIColor.white
        }
    }

    var media: Media!
    var delegate: TrimAudioViewControllerDelegate?
    var uploadingInBackground = false

    private var player: MediaPlayer?
    private var timer: Timer?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        lblSongTitle.text = media.name

        // TODO: refactor 2017-12-08
        if let song = media as? Song {
            let username = song.beat?.producer?.name ?? NSLocalizedString("Unknown", comment: "Unknown username")

            lblProducerName.text = String(format: NSLocalizedString("prod by %@", comment: "Trim audio"), username)
        } else if let video = media as? Video {
            let username = video.beat?.producer?.name ?? NSLocalizedString("Unknown", comment: "Unknown username")

            lblProducerName.text = String(format: NSLocalizedString("prod by %@", comment: "Trim audio"), username)
        } else if let beat = media as? Beat {
            let username = beat.producer?.name ?? NSLocalizedString("Unknown", comment: "Unknown username")

            lblProducerName.text = String(format: NSLocalizedString("prod by %@", comment: "Trim audio"), username)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        do {
            var url: URL
            if uploadingInBackground {
                url = try FileManager.default.tempFolderForProcessingSong(deleteExisting: false)
            } else {
                url = try FileManager.default.folderPath(forMedia: media)
            }
            player = MediaPlayer(url: url)
            player?.delegate = self
        } catch let error {
            self.presentErrorDialog(error: error)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        player?.stop()
        player = nil
    }

    // MARK: - IBActions

    @IBAction func sliderProgressValueDidChange(_ sender: Any) {
        lblTrimStartTime.text = Double(sliderStartTime.value).durationString()

        let track = sliderStartTime.trackRect(forBounds: sliderStartTime.bounds)
        let thumb = sliderStartTime.thumbRect(forBounds: sliderStartTime.bounds, trackRect: track, value: sliderStartTime.value)

        lblTrimStartTimeLeadingConstraint.constant = 45 + thumb.minX
    }

    @IBAction func progressSliderTouchUpInside(_ sender: Any) {
        if btnPlay.isSelected {
            self.player?.seek(to: Double(self.sliderStartTime.value)) { _ in
                self.player?.play()
                self.btnPlay.isSelected = true
            }
        }
    }

    @IBAction func didTapCloseButton(_ sender: Any) {
        delegate?.didDismiss(viewController: self)
    }

    @IBAction func didTapPlayPauseButton(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected

        if sender.isSelected {
            player?.seek(to: Double(sliderStartTime.value)) { _ in
                self.player?.play()
            }
        } else {
            player?.pause()
        }
    }

    @IBAction func didTapConfirmButton(_ sender: Any) {
        guard let asset = player?.asset else {
            return
        }

        view.loading(with: NSLocalizedString("Get Ready to Shoot your New Music Video!", comment: "Trim Audio"))

        btnPlay.isSelected = false
        player?.pause()

        var outputUrl: URL!
        do {
            outputUrl = try FileManager.default.tempFolderPath(forMedia: media)
        } catch let error {
            self.presentErrorDialog(error: error)
            return
        }

        let start = Double(sliderStartTime.value)
        let end = min(start + 60, player?.duration.seconds ?? 0)
        let startTime = CMTime(seconds: start, preferredTimescale: player?.preferredTimescale ?? 0)
        let endTime = CMTime(seconds: end, preferredTimescale: player?.preferredTimescale ?? 0)

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            fatalError()
        }
        exportSession.outputURL = outputUrl
        exportSession.outputFileType = .m4a
        exportSession.timeRange = CMTimeRange(start: startTime, end: endTime)
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.exportAsynchronously(completionHandler: {
            DispatchQueue.main.async {
                self.view.loaded()
                switch exportSession.status {
                case .completed:
                    self.delegate?.didTrimMedia(viewController: self, media: self.media, output: outputUrl)
                case .failed, .cancelled:
                    guard let error = exportSession.error else {
                        return
                    }
                    self.presentErrorDialog(error: error)
                default: break
                }
            }
        })
    }
}

extension TrimAudioViewController: MediaPlayerDelegate {

    func onReadyToPlay(player: MediaPlayer) {
        sliderStartTime.minimumValue = 0
        if !CMTIME_IS_INDEFINITE(player.duration) {
            sliderStartTime.maximumValue = Float(player.duration.seconds)
        }

        lblEndTime.text = player.duration.seconds.durationString()
    }

    func onPeriodicTimeObserver(player: MediaPlayer, time: CMTime) {

    }

    func didPlayToEndTime(player: MediaPlayer) {
        if btnPlay.isSelected {
            player.seek(to: Double(sliderStartTime.value)) { _ in
                player.play()
            }
        }
    }

    func didStartPlaying(player: MediaPlayer) {
        btnPlay.isSelected = true
    }

    func onFailure(error: Error) {
        presentErrorDialog(error: error)
    }
}

extension UIViewController {

    func openTrimAudio(for media: Media) {
        let storyboard = UIStoryboard(name: "ARUser", bundle: Bundle.main)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "TrimAudioViewController") as? TrimAudioViewController else {
            fatalError("couldn't instantiate TrimAudioViewController")
        }

        viewController.media = media
        viewController.delegate = self as? TrimAudioViewControllerDelegate

        self.present(viewController, animated: true, completion: nil)
    }
}
