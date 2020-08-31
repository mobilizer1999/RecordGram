//
//  CaptureVideoViewController.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 10/3/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import NextLevel
import AVFoundation
import Toast_Swift

protocol CaptureVideoViewControllerDelegate {
    func didCaptureVideo(viewController: CaptureVideoViewController, base: Media?, outputUrl: URL)
    func didCancel(viewController: CaptureVideoViewController)
}

class CaptureVideoViewController: UIViewController, ErrorHandler {
    
    @IBOutlet weak var viewCamera: UIView! {
        didSet {
            viewCamera.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        }
    }
    @IBOutlet weak var progressRecording: UIProgressView! {
        didSet {
            progressRecording.setProgress(0, animated: false)
        }
    }
    @IBOutlet weak var viewActions: UIStackView!
    @IBOutlet weak var viewCaptureModes: UIView!
    @IBOutlet weak var btnRecord: UIButton!
    @IBOutlet weak var lblCountdown: UILabel! {
        didSet {
            lblCountdown.layer.cornerRadius = 180 / 2
            lblCountdown.layer.borderColor = UIColor.white.cgColor
            lblCountdown.layer.borderWidth = 2
            lblCountdown.clipsToBounds = true
            lblCountdown.backgroundColor = UIColor(red: 0.65, green: 0.13, blue: 0.07, alpha: 1.00)
            lblCountdown.isHidden = true
        }
    }
    @IBOutlet weak var btnSlowMotion: UIButton! {
        didSet {
            btnSlowMotion.isSelected = false
        }
    }
    @IBOutlet weak var btnNormalMotion: UIButton! {
        didSet {
            btnNormalMotion.isSelected = true
        }
    }
    @IBOutlet weak var btnFastMotion: UIButton! {
        didSet {
            btnFastMotion.isSelected = false
        }
    }
    @IBOutlet weak var recordingIndicator: UIView!
    @IBOutlet weak var menuOptionsView: UIVisualEffectView!
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var flashView: UIView!
    
    private lazy var nextLevel: NextLevel = NextLevel.shared
    private var player: MediaPlayer?
    private var countdown: Int = 0
    private var clips = [AVAsset]()
    private var didPlayToEnd = false
    private var timer: Timer?
    private var savedTime = kCMTimeZero
    private var savedBrightness: CGFloat = 0
    
    var url: URL?
    var base: Media?
    var delegate: CaptureVideoViewControllerDelegate?
    var offsetTime: CMTime? = nil
    var audioStartedTime: TimeInterval?
    var videoStartedTime: TimeInterval?
    var videoEndedTime: TimeInterval?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nextLevel.delegate = self
        nextLevel.videoDelegate = self
        
        if AVCaptureDevice.Position.front.isCameraDevicePositionAvailable {
            nextLevel.devicePosition = .front
        } else {
            nextLevel.devicePosition = .back
        }
        
        nextLevel.captureMode = .video
        nextLevel.flashMode = .off
        nextLevel.focusMode = .continuousAutoFocus
        nextLevel.frameRate = 30
        nextLevel.deviceOrientation = .portrait
        nextLevel.mirroringMode = .on
        
        nextLevel.audioConfiguration.bitRate = 44000
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapView))
        gesture.cancelsTouchesInView = true
        view.addGestureRecognizer(gesture)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressRecordButton))
        btnRecord.addGestureRecognizer(longPressGesture)
        
        AVCaptureDevice.requestAccess(for: .audio) { (granted) in
            guard granted else {
                return
            }
            
            AVCaptureDevice.requestAccess(for: .video) { (granted) in
                guard granted else {
                    return
                }
                
                do {
                    try self.nextLevel.start()
                } catch let error {
                    self.presentErrorDialog(error: error)
                }
            }
        }
        viewCamera.layer.addSublayer(nextLevel.previewLayer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        nextLevel.previewLayer.frame = viewCamera.bounds
        
        if let url = self.url {
            player = MediaPlayer(url: url)
            player?.autoPlay = false
            player?.delegate = self
            player?.player?.seek(to: savedTime)
            
            let preferredTimescale = player?.preferredTimescale ?? CMTimeScale(NSEC_PER_SEC)
            nextLevel.videoConfiguration.maximumCaptureDuration = CMTime(seconds: 60, preferredTimescale: preferredTimescale)
        } else {
            nextLevel.videoConfiguration.maximumCaptureDuration = CMTime(seconds: 60, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        pauseRecording()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        savedTime = player?.currentTime ?? kCMTimeZero
        player?.stop()
        player = nil
    }
    
    deinit {
        nextLevel.stop()
    }
    
    @objc func didTapView(_ gesture: UIGestureRecognizer) {
        guard gesture.state == .ended else {
            return
        }
        
        menuOptionsView.popOut()
    }
    
    @objc func didLongPressRecordButton(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            startRecording()
        case .ended:
            pauseRecording()
        case .cancelled, .changed, .failed, .possible:
            break
        }
    }
    
    func startRecording() {
        guard !nextLevel.isRecording else {
            return
        }
        
        self.nextLevel.record()
        
        viewActions.isHidden = true
        viewCaptureModes.isHidden = true
        
        if url == nil {
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                let progress = (self.nextLevel.session?.totalDuration.seconds ?? 0) / 60
                self.progressRecording.setProgress(Float(progress), animated: true)
            }
        }
        
        UIView.animate(withDuration: 0.7, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 5, options: [.repeat, .autoreverse], animations: {
            self.recordingIndicator.alpha = 1
        }, completion: { _ in
            self.recordingIndicator.alpha = 0
        })
        if flashButton.isSelected {
            turnFlashOn()
        }
    }
    
    func pauseRecording() {
        guard nextLevel.isRecording else {
            return
        }
        
        player?.pause()
        nextLevel.pause()
        
        viewActions.isHidden = false
        viewCaptureModes.isHidden = false
        
        recordingIndicator.layer.removeAllAnimations()
        timer?.invalidate()
        if flashButton.isSelected {
            turnFlashOff()
        }
    }
    
    // TODO: 2017-12-22 refactor
    func mergeClips(videoAssets: [AVAsset], audioAsset: AVAsset?) -> AVMutableComposition {
        let composition = AVMutableComposition()
        
        var currentVideoTime = CMTime(seconds: 0, preferredTimescale: player?.preferredTimescale ?? CMTimeScale(NSEC_PER_SEC))
        var currentAudioTime = self.offsetTime ?? currentVideoTime
        
        var videoTrack: AVMutableCompositionTrack?
        var audioTrack: AVMutableCompositionTrack?
        
        videoAssets.forEach({ videoAsset in
            
            // clips
            videoAsset.tracks(withMediaType: .video).forEach { track in
                
                // videos
                if videoTrack == nil {
                    videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
                }
                
                if let videoTrack = videoTrack {
                    let timeRange = CMTimeRange(start: currentVideoTime, duration: track.timeRange.duration)
                    
                    do {
                        try videoTrack.insertTimeRange(track.timeRange, of: track, at: currentVideoTime)
                    } catch let error {
                        self.presentErrorDialog(error: error)
                    }
                    currentVideoTime = timeRange.end
                }
            }
            
            let audios = videoAsset.tracks(withMediaType: .audio)
            
            if audios.isEmpty {
                currentAudioTime = currentVideoTime
            }
            
            audios.forEach({ track in
                
                // audios
                if audioTrack == nil {
                    audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
                }
                
                if let audioTrack = audioTrack {
                    let timeRange = CMTimeRange(start: currentAudioTime, duration: track.timeRange.duration)
                    
                    do {
                        try audioTrack.insertTimeRange(track.timeRange, of: track, at: currentAudioTime)
                    } catch let error {
                        self.presentErrorDialog(error: error)
                    }
                    
                    currentAudioTime = timeRange.end
                }
            })
        })
        
        if let track = audioAsset?.tracks(withMediaType: .audio).first {
            if let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
                currentAudioTime = self.offsetTime ?? CMTime(seconds: 0, preferredTimescale: player?.preferredTimescale ?? CMTimeScale(NSEC_PER_SEC))
                
                let timeRange = CMTimeRange(start: kCMTimeZero, duration: currentVideoTime - currentAudioTime)
                
                do {
                    try audioTrack.insertTimeRange(timeRange, of: track, at: currentAudioTime)
                } catch let error {
                    self.presentErrorDialog(error: error)
                }
            }
        }
        
        return composition
    }
    
    // TODO: refactor 2017-12-14
    func videoComposition(composition: AVMutableComposition) -> AVMutableVideoComposition? {
        guard let videoTrack = composition.tracks(withMediaType: .video).first else {
            return nil
        }
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: kCMTimeZero, duration: composition.duration)
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        
        layerInstruction.setTransform(videoTrack.preferredTransform, at: kCMTimeZero)
        layerInstruction.setOpacity(0.0, at: composition.duration)
        
        instruction.layerInstructions = [layerInstruction]
        
        let t = composition.preferredTransform
        let isVideoAssetPortrait = (t.a == 0 && t.b == 1 && t.c == -1 && t.d == 0) || (t.a == 0 && t.b == -1 && t.c == 1 && t.d == 0)
        
        let videoComposition = AVMutableVideoComposition()
        
        var naturalSize = CGSize()
        if isVideoAssetPortrait {
            naturalSize = CGSize(width: videoTrack.naturalSize.height, height: videoTrack.naturalSize.width)
        } else {
            naturalSize = videoTrack.naturalSize
        }
        
        videoComposition.renderSize = naturalSize
        videoComposition.instructions = [instruction]
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        
        let txtUsername = CATextLayer()
        // FIXME: 2017-12-06 remove hard coded username
        txtUsername.string = "@\(UserDefaults.standard.string(forKey: kUserNameKey) ?? "hprione")"
        txtUsername.font = UIFont(name: "ProductSans-Regular", size: 48)
        txtUsername.fontSize = 48
        txtUsername.frame = CGRect(x: 5, y: 30, width: naturalSize.width - 10, height: 80)
        txtUsername.alignmentMode = kCAAlignmentRight
        txtUsername.foregroundColor = UIColor.white.cgColor
        txtUsername.opacity = 1
        
        let txtRecordGram = CATextLayer()
        txtRecordGram.string = NSLocalizedString("Cre8tor", comment: "App name")
        txtRecordGram.font = UIFont(name: "ProductSans-Bold", size: 56)
        txtRecordGram.fontSize = 56
        txtRecordGram.frame = CGRect(x: 5, y: 5, width: naturalSize.width - 10, height: 60)
        txtRecordGram.alignmentMode = kCAAlignmentRight
        txtRecordGram.foregroundColor = UIColor.white.cgColor
        txtRecordGram.opacity = 1
        
        let overlayLayer = CALayer()
        overlayLayer.frame = CGRect(x: 0, y: 0, width: naturalSize.width, height: naturalSize.height)
        overlayLayer.addSublayer(txtUsername)
        overlayLayer.addSublayer(txtRecordGram)
        overlayLayer.masksToBounds = true
        
        let parentLayer = CALayer()
        let videoLayer = CALayer()
        
        parentLayer.frame = CGRect(x: 0, y: 0, width: naturalSize.width, height: naturalSize.height)
        videoLayer.frame = CGRect(x: 0, y: 0, width: naturalSize.width, height: naturalSize.height)
        
        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(overlayLayer)
        
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
        
        return videoComposition
    }
    
    // FIXME: 2017-12-22 delete this
    @discardableResult
    func appendTrack(track: AVAssetTrack, toCompositionTrack compositionTrack: AVMutableCompositionTrack, withStartTime time: CMTime, range: CMTime) -> CMTime {
        var timeRange = track.timeRange
        let startTime = time + timeRange.start
        
        if range.isValid {
            let currentRange = startTime + timeRange.duration
            
            if currentRange > range {
                timeRange = CMTimeRange(start: timeRange.start, duration: (timeRange.duration - (currentRange - range)))
            }
        }
        
        if timeRange.duration > kCMTimeZero {
            do {
                try compositionTrack.insertTimeRange(timeRange, of: track, at: startTime)
            } catch let error {
                self.presentErrorDialog(error: error)
            }
            return (startTime + timeRange.duration)
        }
        
        return startTime
    }
    
    func didSave() {
        view.loading(with: NSLocalizedString("Preparing your Awesome Video!", comment: "Capture Video"))
        pauseRecording()
        
        if offsetTime == nil {
            return
        }
        
        var audioAsset: AVAsset?
        
        if let url = self.url {
            audioAsset = AVAsset(url: url)
        }
        
        let composition = mergeClips(videoAssets: clips, audioAsset: audioAsset)
        
        var outputUrl: URL!
        do {
            outputUrl = try FileManager.default.tempFolderForProcessingVideo()
        } catch let error {
            self.presentErrorDialog(error: error)
            self.view.loaded()
            return
        }
        
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            fatalError()
        }
        exportSession.outputFileType = .mp4
        exportSession.outputURL = outputUrl
        exportSession.videoComposition = self.videoComposition(composition: composition)
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                self.view.loaded()
                switch exportSession.status {
                case .completed:
                    self.delegate?.didCaptureVideo(viewController: self, base: self.base, outputUrl: outputUrl)
                case .failed, .cancelled:
                    guard let error = exportSession.error else {
                        return
                    }
                    self.presentErrorDialog(error: error)
                default:
                    break
                }
            }
        }
    }
    
    func reachedEnd() {
        didPlayToEnd = true
        viewActions.isHidden = false
        viewCaptureModes.isHidden = false
        
        recordingIndicator.layer.removeAllAnimations()
        timer?.invalidate()
    }
    
    func turnFlashOn() {
        if (nextLevel.isTorchAvailable) {
            nextLevel.torchMode = .on
        } else {
            flashView.alpha = 0.8
            savedBrightness = UIScreen.main.brightness
            UIScreen.main.brightness = 1
        }
        
    }
    
    func turnFlashOff() {
        if (nextLevel.isTorchAvailable) {
            nextLevel.torchMode = .off
        } else {
            flashView.alpha = 0
            UIScreen.main.brightness = savedBrightness
        }
        
    }
    
    // MARK: - IBActions
    
    @IBAction func didTapContinueShootingButton(_ sender: Any) {
        menuOptionsView.popOut()
    }
    
    @IBAction func didTapFlipCameraButton(_ sender: Any) {
        menuOptionsView.popOut() { _ in
            self.nextLevel.flipCaptureDevicePosition()
        }
    }
    
    @IBAction func didTapStartShootingButton(_ sender: Any) {
        menuOptionsView.popOut() { _ in
            self.didTapStartRecordingHandsFreeButton(sender)
        }
    }
    
    @IBAction func didTapStartRecordingButton(_ sender: Any) {
        pauseRecording()
    }
    
    @IBAction func didTapStartRecordingHandsFreeButton(_ sender: Any) {
        guard !nextLevel.isRecording else {
            pauseRecording()
            
            return
        }
        
        countdown = 5
        lblCountdown.text = String(countdown)
        lblCountdown.isHidden = false
        
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            self.countdown = self.countdown - 1
            
            if self.countdown <= 0 {
                timer.invalidate()
                
                self.lblCountdown.isHidden = true
                self.startRecording()
                
                return
            }
            
            self.lblCountdown.text = String(self.countdown)
        }
    }
    
    @IBAction func didTapCloseButton(_ sender: Any) {
        menuOptionsView.popIn()
    }
    
    @IBAction func didTapSaveVideoButton(_ sender: Any) {
        didSave()
    }
    
    @IBAction func didTapExitCameraButton(_ sender: Any) {
        delegate?.didCancel(viewController: self)
    }
    
    @IBAction func didTapSwitchCameraModeButton(_ sender: Any) {
        nextLevel.flipCaptureDevicePosition()
    }
    
    @IBAction func didTapToggleFlashButton(_ sender: Any) {
        if nextLevel.isRecording {
            if flashButton.isSelected {
                turnFlashOff()
            } else {
                turnFlashOn()
            }
        }
        
        flashButton.isSelected = !flashButton.isSelected
    }
    
    @IBAction func didTapSlowMotionButton(_ sender: Any) {
        btnSlowMotion.isSelected = true
        btnNormalMotion.isSelected = false
        btnFastMotion.isSelected = false
        
        player?.fastMotion()
    }
    
    @IBAction func didTapNormalButton(_ sender: Any) {
        btnSlowMotion.isSelected = false
        btnNormalMotion.isSelected = true
        btnFastMotion.isSelected = false
        
        player?.normalMotion()
    }
    
    @IBAction func didTapFastMotionButton(_ sender: Any) {
        btnSlowMotion.isSelected = false
        btnNormalMotion.isSelected = false
        btnFastMotion.isSelected = true
        
        player?.slowMotion()
    }
    
    @IBAction func didTapReRecordVideo(_ sender: Any) {
        clips.removeAll()
        player?.player?.seek(to: kCMTimeZero)
        progressRecording.setProgress(0, animated: false)
        nextLevel.session?.removeAllClips(removeFiles: true)
        menuOptionsView.popOut()
    }
}

extension CaptureVideoViewController: NextLevelDelegate {
    func nextLevel(_ nextLevel: NextLevel, didUpdateAuthorizationStatus status: NextLevelAuthorizationStatus, forMediaType mediaType: AVMediaType) {
    }
    
    func nextLevel(_ nextLevel: NextLevel, didUpdateVideoConfiguration videoConfiguration: NextLevelVideoConfiguration) {
    }
    
    func nextLevel(_ nextLevel: NextLevel, didUpdateAudioConfiguration audioConfiguration: NextLevelAudioConfiguration) {
    }
    
    func nextLevelSessionWillStart(_ nextLevel: NextLevel) {
    }
    
    func nextLevelSessionDidStart(_ nextLevel: NextLevel) {
    }
    
    func nextLevelSessionDidStop(_ nextLevel: NextLevel) {
    }
    
    func nextLevelSessionWasInterrupted(_ nextLevel: NextLevel) {
    }
    
    func nextLevelSessionInterruptionEnded(_ nextLevel: NextLevel) {
    }
    
    func nextLevelCaptureModeWillChange(_ nextLevel: NextLevel) {
    }
    
    func nextLevelCaptureModeDidChange(_ nextLevel: NextLevel) {
    }
}

extension CaptureVideoViewController: NextLevelVideoDelegate {
    func nextLevel(_ nextLevel: NextLevel, didUpdateVideoZoomFactor videoZoomFactor: Float) {
    }
    
    func nextLevel(_ nextLevel: NextLevel, willProcessRawVideoSampleBuffer sampleBuffer: CMSampleBuffer, onQueue queue: DispatchQueue) {
    }
    
    func nextLevel(_ nextLevel: NextLevel, renderToCustomContextWithImageBuffer imageBuffer: CVPixelBuffer, onQueue queue: DispatchQueue) {
    }
    
    func nextLevel(_ nextLevel: NextLevel, willProcessFrame frame: AnyObject, pixelBuffer: CVPixelBuffer, timestamp: TimeInterval, onQueue queue: DispatchQueue) {
    }
    
    func nextLevel(_ nextLevel: NextLevel, didSetupVideoInSession session: NextLevelSession) {
    }
    
    func nextLevel(_ nextLevel: NextLevel, didSetupAudioInSession session: NextLevelSession) {
    }
    
    func nextLevel(_ nextLevel: NextLevel, didStartClipInSession session: NextLevelSession) {
        self.player?.play()
    }
    
    func nextLevel(_ nextLevel: NextLevel, didCompleteClip clip: NextLevelClip, inSession session: NextLevelSession) {
        clip.isMutedOnMerge = btnSlowMotion.isSelected || btnFastMotion.isSelected // setting this value in case we use NextLevel.mergeClips in the future
        
        if self.offsetTime == nil {
//            self.offsetTime = clip.duration - (player?.currentTime)!
            self.offsetTime = clip.duration - CMTime(seconds: videoEndedTime! - videoStartedTime!, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        }
        
        guard let videoAssetTrack = clip.asset?.tracks(withMediaType: .video).first else {
            return
        }
        
        let composition = AVMutableComposition()
        let timeRange = CMTimeRange(start: kCMTimeZero, duration: clip.duration)
        
        guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            return
        }
        
        appendTrack(track: videoAssetTrack, toCompositionTrack: videoTrack, withStartTime: kCMTimeZero, range: kCMTimePositiveInfinity)
        
        if btnSlowMotion.isSelected {
            composition.scaleTimeRange(timeRange, toDuration: CMTime(seconds: clip.duration.seconds * 2.0, preferredTimescale: clip.duration.timescale))
        } else if btnFastMotion.isSelected {
            composition.scaleTimeRange(timeRange, toDuration: CMTime(seconds: clip.duration.seconds * 0.2, preferredTimescale: clip.duration.timescale))
        } else { // normal motion has audio only if there is no other audio source
            if self.url == nil {
                if let audioAssetTrack = clip.asset?.tracks(withMediaType: .audio).first, let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
                    appendTrack(track: audioAssetTrack, toCompositionTrack: audioTrack, withStartTime: kCMTimeZero, range: kCMTimePositiveInfinity)
                }
            }
        }
        
        var outputUrl: URL!
        do {
            outputUrl = try FileManager.default.tempFolderForProcessingClip(index: clips.count)
        } catch let error {
            self.presentErrorDialog(error: error)
            return
        }
        
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            fatalError()
        }
        exportSession.outputFileType = .mp4
        exportSession.outputURL = outputUrl
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                switch exportSession.status {
                case .completed:
                    let asset = AVURLAsset(url: outputUrl)
                    self.clips.append(asset)
                    if self.didPlayToEnd {
                        self.didSave()
                    }
                case .failed, .cancelled:
                    guard let error = exportSession.error else {
                        return
                    }
                    self.presentErrorDialog(error: error)
                default:
                    break
                }
            }
        }
    }
    
    func nextLevel(_ nextLevel: NextLevel, didAppendVideoSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
        if videoStartedTime == nil {
            videoStartedTime = Date().timeIntervalSince1970
        }
        videoEndedTime = NSDate().timeIntervalSince1970
    }
    
    func nextLevel(_ nextLevel: NextLevel, didSkipVideoSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
    }
    
    func nextLevel(_ nextLevel: NextLevel, didAppendVideoPixelBuffer pixelBuffer: CVPixelBuffer, timestamp: TimeInterval, inSession session: NextLevelSession) {
    }
    
    func nextLevel(_ nextLevel: NextLevel, didSkipVideoPixelBuffer pixelBuffer: CVPixelBuffer, timestamp: TimeInterval, inSession session: NextLevelSession) {
    }
    
    func nextLevel(_ nextLevel: NextLevel, didAppendAudioSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
    }
    
    func nextLevel(_ nextLevel: NextLevel, didSkipAudioSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
    }
    
    func nextLevel(_ nextLevel: NextLevel, didCompleteSession session: NextLevelSession) {
        reachedEnd()
    }
    
    func nextLevel(_ nextLevel: NextLevel, didCompletePhotoCaptureFromVideoFrame photoDict: [String: Any]?) {
    }
}

extension CaptureVideoViewController: MediaPlayerDelegate {
    func onReadyToPlay(player: MediaPlayer) {
        nextLevel.videoConfiguration.maximumCaptureDuration = player.duration
    }
    
    func onPeriodicTimeObserver(player: MediaPlayer, time: CMTime) {
        let progress = Float(time.seconds / player.duration.seconds)
        
        progressRecording.setProgress(progress, animated: true)
    }
    
    func didPlayToEndTime(player: MediaPlayer) {
        reachedEnd()
    }
    
    func didStartPlaying(player: MediaPlayer) {
        audioStartedTime = Date().timeIntervalSince1970
    }
    
    func onFailure(error: Error) {
        presentErrorDialog(error: error)
    }
}
