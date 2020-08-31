//
//  MediaPlayer.swift
//  RecordGram
//
//  Created by Hugo Prione on 13/11/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import AVFoundation
import CoreImage
import ACBAVPlayer

protocol MediaPlayerDelegate {
    func onReadyToPlay(player: MediaPlayer)
    func onPeriodicTimeObserver(player: MediaPlayer, time: CMTime)
    func onAveragePower(_ power: CGFloat)
    func didPlayToEndTime(player: MediaPlayer)
    func onFailure(error: Error)
    func didStartPlaying(player: MediaPlayer)
}

extension MediaPlayerDelegate {
    func onAveragePower(_ power: CGFloat) {
    }
}

struct MediaPlayerVideoFilter {
    var title: String
    var ciFilter: String
}

final class MediaPlayer: NSObject {
    var delegate: MediaPlayerDelegate?
    var autoPlay: Bool
    var currentTime: CMTime {
        get {
            return playerItem?.currentTime() ?? kCMTimeZero
        }
    }
    var duration: CMTime {
        get {
            return playerItem?.duration ?? kCMTimeIndefinite
        }
    }
    var preferredTimescale: CMTimeScale {
        get {
            return duration.timescale
        }
    }
    var asset: AVAsset? {
        get {
            return playerItem?.asset
        }
    }
    var playerView: PlayerView? {
        didSet {
            playerView?.player = player
        }
    }
    var videoComposition: AVVideoComposition? {
        didSet {
            playerItem?.videoComposition = videoComposition
        }
    }
    var volume: Float {
        get {
            return player?.volume ?? 0.0
        }

        set {
            player?.volume = newValue
        }
    }
    var loop: Bool

    static var availableVideoFilters: [MediaPlayerVideoFilter] {
        get {
            return [MediaPlayerVideoFilter(title: NSLocalizedString("Normal", comment: "Filter name"), ciFilter: ""),
                    MediaPlayerVideoFilter(title: NSLocalizedString("Country", comment: "Filter name"), ciFilter: "CISepiaTone"),
                    MediaPlayerVideoFilter(title: NSLocalizedString("Winter", comment: "Filter name"), ciFilter: "CIPhotoEffectProcess"),
                    MediaPlayerVideoFilter(title: NSLocalizedString("Black N White", comment: "Filter name"), ciFilter: "CIPhotoEffectNoir"),
                    MediaPlayerVideoFilter(title: NSLocalizedString("Sunrise", comment: "Filter name"), ciFilter: "CIPhotoEffectTransfer"),
                    MediaPlayerVideoFilter(title: NSLocalizedString("Artistic", comment: "Filter name"), ciFilter: "CIColorPosterize")]
        }
    }

    private var url: URL?
    private var playerItem: AVPlayerItem? {
        didSet {
            playerItem?.videoComposition = videoComposition
        }
    }
    var player: AVPlayer? {
        didSet {
            playerView?.player = player
        }
    }
    private var playerItemContext: Int
    private var observer: Any?
    private var rate: Float

    override init() {
        autoPlay = true
        rate = 1.0
        playerItemContext = 0
        loop = false

        super.init()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)

        playerItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: &playerItemContext)

        print("AppDebug - Deinit MediaPlayer")
    }

    convenience init(url: URL, withMetering: Bool = false) {
        self.init()

        self.url = url

        guard let url = self.url else {
            return
        }
        pause()

        let asset = AVAsset(url: url)
        let assetKeys = ["tracks", "playable", "duration"]

        playerItem = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: assetKeys)
        playerItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.old, .new], context: &playerItemContext)
        playerItem?.preferredForwardBufferDuration = 30

        player = AVPlayer(playerItem: playerItem)
        player?.automaticallyWaitsToMinimizeStalling = true
        player?.isMeteringEnabled = withMetering

        if withMetering {
            player?.averagePowerListInLinearForm() { averagePowerList, success in
                var totalPower: CGFloat = 0;
                if let averagePowerList = averagePowerList {
                    for averagePower in averagePowerList {
                        if let averagePowerDouble = averagePower as? CGFloat {
                            totalPower += averagePowerDouble
                        }
                    }
                }
                // Really Normalize Between 0 & 1
                self.delegate?.onAveragePower(1 - pow(2, -totalPower * 3))
            }
        }

        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }

    @objc internal func playerDidFinishPlaying() {
        let diff = duration.seconds - currentTime.seconds
        guard diff <= 0.06 else {
            return
        }

        delegate?.didPlayToEndTime(player: self)

        if loop {
            seek(to: 0, completionHandler: { _ in
                self.play()
            })
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        // Only handle observations for the playerItemContext
        guard context == &playerItemContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }

        if keyPath == #keyPath(AVPlayerItem.status) {
            let status: AVPlayerItemStatus
            // Get the status change from the change dictionary
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItemStatus(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }

            // Switch over the status
            switch status {
            case .readyToPlay:
                // Player item is ready to play.
                if autoPlay {
                    play()
                }
                self.delegate?.onReadyToPlay(player: self)
            case .failed:
                guard let error = playerItem?.error else {
                    return
                }
                self.delegate?.onFailure(error: error)
            // Player item failed. See error.
            case .unknown:
                break;
                // Player item is not yet ready.
            }
        }
    }

    func play() {
        if observer == nil {
            observer = player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1 / Double(NSEC_PER_SEC), preferredTimescale: CMTimeScale(NSEC_PER_SEC)), queue: nil, using: { time in
                self.delegate?.onPeriodicTimeObserver(player: self, time: time)
                if time.value == 0 {
                    self.delegate?.didStartPlaying(player: self)
                }
            })
        }

        player?.rate = rate
    }

    func seek(to seconds: Double, completionHandler: @escaping (Bool) -> Void) {
        let time = CMTime(seconds: seconds, preferredTimescale: preferredTimescale)

        guard time.isValid else {
            return
        }

        player?.seek(to: time, completionHandler: completionHandler)
    }

    func pause() {
        if let observer = self.observer {
            player?.removeTimeObserver(observer)
            self.observer = nil
        }

        player?.pause()
    }

    func stop() {
        pause()
        player?.stop()

        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
            self.player = nil
        }
    }

    func slowMotion() {
        guard playerItem?.canPlaySlowForward == true else {
            return
        }
        rate = 0.2
    }

    func normalMotion() {
        rate = 1
    }

    func fastMotion() {
        guard playerItem?.canPlayFastForward == true else {
            return
        }
        rate = 2
    }

    func applyVideoFilter(filter: MediaPlayerVideoFilter) {
        guard let asset = self.asset else {
            return
        }

        let filter = CIFilter(name: filter.ciFilter)

        videoComposition = AVVideoComposition(asset: asset, applyingCIFiltersWithHandler: { request in
            guard let filter = filter else {
                request.finish(with: request.sourceImage, context: nil)
                return
            }

            // Clamp to avoid blurring transparent pixels at the image edges
            let source = request.sourceImage.clampedToExtent()

            filter.setValue(source, forKey: kCIInputImageKey)

            // Crop the blurred output to the bounds of the original image
            let output = filter.outputImage!.cropped(to: request.sourceImage.extent)

            // Provide the filter output to the composition
            request.finish(with: output, context: nil)
        })
    }
}

