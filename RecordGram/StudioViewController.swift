//
//  StudioViewController.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/5/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import Pulsator
import AudioKit
import AudioKitUI
import AVFoundation
import SnapKit
import CountdownLabel
import Toast_Swift

class StudioViewController: UIViewController, ErrorHandler {

    enum State {
        case loading
        case readyToRecord
        case recording
        case readyToPlay
        case playing
    }

    @IBOutlet weak var viewMixer: UIView! {
        didSet {
            viewMixer.alpha = 0
            viewMixer.isHidden = true
        }
    }
    @IBOutlet weak var viewActions: UIView! {
        didSet {
            viewActions.alpha = 0
            viewActions.isHidden = true
        }
    }
    @IBOutlet weak var viewMicHud: UIView! {
        didSet {
            viewMicHud.isUserInteractionEnabled = false // this is to avoid clicking on the view, and to be possible to fire button pressed event on button behind
            viewMicHud.alpha = 0
            viewMicHud.isHidden = true
        }
    }
    @IBOutlet weak var btnProfile: RoundButton!
    @IBOutlet weak var btnRecord: UIButton!
    @IBOutlet weak var btnChooseBeat: UIButton! {
        didSet {
            btnChooseBeat.layer.shadowColor = UIColor.black.cgColor
            btnChooseBeat.layer.shadowOffset = CGSize(width: 0, height: 1)
            btnChooseBeat.layer.shadowOpacity = 0.6
        }
    }
    @IBOutlet weak var sldProgress: UISlider! {
        didSet {
            sldProgress.minimumTrackTintColor = UIColor(red: 0.97, green: 0.84, blue: 0.87, alpha: 1.00)
            sldProgress.maximumTrackTintColor = UIColor(red: 0.13, green: 0.00, blue: 0.12, alpha: 1.00)
            sldProgress.tintColor = UIColor(red: 0.13, green: 0.00, blue: 0.12, alpha: 1.00)
            sldProgress.isUserInteractionEnabled = false
            sldProgress.setValue(0, animated: true)
        }
    }
    @IBOutlet weak var sldLocalVolume: UISlider! {
        didSet {
            sldLocalVolume.minimumTrackTintColor = UIColor(red: 0.97, green: 0.84, blue: 0.87, alpha: 1.00)
            sldLocalVolume.maximumTrackTintColor = UIColor(red: 0.13, green: 0.00, blue: 0.12, alpha: 1.00)
            sldLocalVolume.tintColor = UIColor(red: 0.13, green: 0.00, blue: 0.12, alpha: 1.00)
        }
    }
    @IBOutlet weak var btnPlayPause: UIButton!
    @IBOutlet weak var lblBeatDuration: UILabel! {
        didSet {
            lblBeatDuration.text = 0.0.durationString()
        }
    }
    @IBOutlet weak var btnMonitor: UIButton!
    @IBOutlet weak var lblRecordingInfo: UILabel!
    @IBOutlet var inputPlot: AKNodeOutputPlot! {
        didSet {
            inputPlot.plotType = .buffer
            inputPlot.shouldFill = true
            inputPlot.shouldMirror = true
            inputPlot.color = UIColor.red
        }
    }
    @IBOutlet weak var txtLyrics: UITextView!
    @IBOutlet weak var toolbarBottomLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var lyricsView: UIVisualEffectView!

    private var lyric: Lyric!
    private var menuVC: MenuViewController!
    private var preparingToRecord = false
    private var uploadInBackground = false
    private lazy var lblCountdown: CountdownLabel = {
        let lblCountdown = CountdownLabel(frame: btnRecord.frame)
        lblCountdown.countdownDelegate = self
        lblCountdown.timeFormat = "s"
        lblCountdown.layer.cornerRadius = 0.5 * lblCountdown.bounds.size.width
        lblCountdown.layer.borderColor = UIColor.white.cgColor
        lblCountdown.layer.borderWidth = 2.0
        lblCountdown.clipsToBounds = true
        lblCountdown.backgroundColor = UIColor(red: 0.24, green: 0.07, blue: 0.23, alpha: 1.00)
        lblCountdown.textAlignment = .center
        lblCountdown.textColor = UIColor.white
        lblCountdown.font = .productSansRegularOfSize80
        lblCountdown.isHidden = true

        self.view.addSubview(lblCountdown)

        lblCountdown.snp.makeConstraints { make in
            make.width.height.equalTo(btnRecord)
            make.center.equalTo(btnRecord)
        }

        return lblCountdown
    }()
    private lazy var pulsator: Pulsator = {
        let pulsator = Pulsator()

        pulsator.backgroundColor = UIColor.red.cgColor
        pulsator.radius = 45
        pulsator.animationDuration = 4
        pulsator.numPulse = 3
        pulsator.position = CGPoint(x: btnMonitor.center.x, y: btnMonitor.center.y)

        btnMonitor.layer.addSublayer(pulsator)

        return pulsator
    }()
    private lazy var count = 0
    private var micBooster: AKBooster?
    private var recorder: AKNodeRecorder?
    private var state = State.loading
    private var animator: UIDynamicAnimator?
    private var player: AKAudioPlayer?
    private var mediaPlayer: MediaPlayer? {
        didSet {
            mediaPlayer?.delegate = self
            mediaPlayer?.autoPlay = false
        }
    }
    private var recordsPlayer: MediaPlayer? {
        didSet {
            recordsPlayer?.delegate = self
            recordsPlayer?.autoPlay = false
        }
    }

    var media: Media? {
        didSet {
            btnPlayPause.isSelected = false

            guard let media = media else {
                btnPlayPause.isUserInteractionEnabled = false
                sldProgress.isUserInteractionEnabled = false

                btnChooseBeat?.setTitle(NSLocalizedString("Choose a Beat", comment: "Studio"), for: .normal)
                return
            }

            var url: URL!
            do {
                url = try FileManager.default.folderPath(forMedia: media)
            } catch let error {
                self.presentErrorDialog(error: error)
                return
            }

            mediaPlayer?.stop()
            mediaPlayer = nil

            mediaPlayer = MediaPlayer(url: url)

            mediaPlayer?.volume = 0.5

            btnPlayPause.isUserInteractionEnabled = true
            sldProgress.isUserInteractionEnabled = true

            btnChooseBeat?.setTitle(media.name, for: .normal)
        }
    }
    var menuView: UIView!

    let session = AVAudioSession.sharedInstance()

    override func viewDidLoad() {
        super.viewDidLoad()

        lyric = Lyric()
        self.txtLyrics.text = lyric.body
        self.txtLyrics.textContainerInset = UIEdgeInsetsMake(13, 0, 13, 13)

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapView(_:)))
        self.view.addGestureRecognizer(tap)
        
        NotificationCenter.default.addObserver(self, selector: #selector(audioRouteChangeListener), name: NSNotification.Name.AVAudioSessionRouteChange, object: nil)
        
        insertMenu()

        DispatchQueue.global(qos: .background).async {
            AKAudioFile.cleanTempDirectory()

            // Session settings
            AKSettings.bufferLength = .medium

            do {
                try AKSettings.setSession(category: .playAndRecord, with: [.allowBluetooth, .mixWithOthers])
            } catch let error {
                self.presentErrorDialog(error: error)
            }
            
            AKSettings.useBluetooth = true
//            AKSettings.defaultToSpeaker = true

            let mic = AKMicrophone()

            self.micBooster = AKBooster(mic, gain: 0.1)
            self.micBooster?.gain = 0
            do {
                self.recorder = try AKNodeRecorder(node: mic)
            } catch let error {
                fatalError(error.localizedDescription)
            }

            if let file = self.recorder?.audioFile {
                do {
                    self.player = try AKAudioPlayer(file: file)
                } catch let error {
                    self.presentErrorDialog(error: error)
                }
            } else {
                self.presentErrorDialog(string: NSLocalizedString("Could not record...", comment: "Studio"))
            }

            // TODO: 2018-01-03 refactor review
            self.player?.completionHandler = {
                DispatchQueue.main.async {
                    if (self.player?.duration ?? 0) > (self.recordsPlayer?.duration.seconds ?? 0) {
                        self.reset {
                            self.mediaPlayer?.play()
                            self.recordsPlayer?.play()
                            self.player?.play()
                        }
                    }
                }
            }

            AudioKit.output = AKMixer(self.player, self.micBooster)

            do {
                try AudioKit.start()
                self.state = .readyToRecord
            } catch {
                self.presentErrorDialog(error: error)
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.title = NSLocalizedString("STUDIO", comment: "Studio")
        load(btnProfile)

        tabBarController?.tabBar.isHidden = false
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        let insetAmount = (btnChooseBeat.bounds.width / 2.0) - 50 //width of image + spacing

        btnChooseBeat.layer.cornerRadius = btnChooseBeat.frame.height / 2
        btnChooseBeat.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -insetAmount)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        mediaPlayer?.pause()
        recordsPlayer?.pause()
        player?.stop()
        btnPlayPause.isSelected = false
        do {
            try recorder?.reset()
        } catch let error {
            presentErrorDialog(error: error)
        }
        state = .readyToRecord

        stopSpinAnimation()
        viewMicHud.fadeOut(completion: { _ in
            self.viewMicHud.isHidden = true
        })
        
        output(through: .speaker)
        stopMonitoring()

        didTapCloseNotepadButton(self)
    }
    
    @objc func audioRouteChangeListener(notification: NSNotification) {
        let audioRouteChangeReason = notification.userInfo![AVAudioSessionRouteChangeReasonKey] as! UInt
        
        switch audioRouteChangeReason {
        case AVAudioSessionRouteChangeReason.newDeviceAvailable.rawValue:
            // headphones plugged in
            output(through: .none)
        case AVAudioSessionRouteChangeReason.oldDeviceUnavailable.rawValue:
            // headphones unplugged
            if state == .recording {
                output(through: .none)
            } else {
                output(through: .speaker)
            }
        default:
            break
        }
    }
    
    func insertMenu() {
        if let window = UIApplication.shared.keyWindow {
            let storyboard = UIStoryboard(name: "Menu", bundle: nil)
            menuVC = storyboard.instantiateViewController(withIdentifier: "menu") as! MenuViewController
            menuVC.studioVC = self
            menuView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
            menuView.isUserInteractionEnabled = false
            menuView.addSubview(menuVC.view)
            window.addSubview(menuView)
        }
    }

    func showMyStudio() {
        let storyBoard = UIStoryboard(name: "MyStudioPopover", bundle: nil)
        let studioPopverVC = storyBoard.instantiateViewController(withIdentifier: "StudioPopoverViewController") as! MyStudioPopoverViewController
        studioPopverVC.modalPresentationStyle = .overCurrentContext
        //studioPopverVC.homeVC = studioVC
        studioPopverVC.delegate = self
        self.present(studioPopverVC, animated: true, completion: nil)
    }

    func animateRecordingStarted() {
        viewMicHud.isHidden = false
        viewMicHud.fadeIn()
    }

    func animateRecordingStopped() {
        viewMixer.popIn()

        viewActions.fadeOut(completion: { _ in
            self.viewActions.isHidden = true
        })

        viewMicHud.fadeOut(completion: { _ in
            self.viewMicHud.isHidden = true
        })
    }

    func showNoBeatWarning() {
        view.makeToast(NSLocalizedString("Please select a beat first.", comment: "Studio"), duration: 3, position: .center)

        btnChooseBeat.layer.borderColor = UIColor.init(hex: "FFB830").cgColor
        btnChooseBeat.layer.borderWidth = 1

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1)) {
            self.btnChooseBeat.layer.borderColor = UIColor.clear.cgColor
            self.btnChooseBeat.layer.borderWidth = 0.0
        }
    }

    func startSpinAnimation() {
        guard animator == nil else {
            return
        }

        animator = UIDynamicAnimator(referenceView: btnRecord)

        let spinBehavior = UIDynamicItemBehavior()
        spinBehavior.addItem(btnRecord)
        spinBehavior.addAngularVelocity(.pi / 2, for: btnRecord)
        spinBehavior.angularResistance = 0.0

        animator?.addBehavior(spinBehavior)
    }

    func stopSpinAnimation() {
        animator?.removeAllBehaviors()
        animator = nil

        btnRecord.transform = CGAffineTransform(rotationAngle: 0.0)

        UIView.animate(withDuration: 0.2) {
            self.btnRecord.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        }
    }

    func merge(vocalAsset: AVAsset) -> AVMutableComposition {
        let composition = AVMutableComposition()

        recordsPlayer?.asset?.tracks(withMediaType: .audio).forEach({ track in
            guard let compositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
                fatalError()
            }
            do {
                try compositionTrack.insertTimeRange(track.timeRange, of: track, at: kCMTimeZero)
            } catch let error {
                self.presentErrorDialog(error: error)
            }
        })

        vocalAsset.tracks(withMediaType: .audio).forEach({ track in
            guard let compositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
                fatalError()
            }
            do {
                try compositionTrack.insertTimeRange(track.timeRange, of: track, at: kCMTimeZero)
            } catch let error {
                self.presentErrorDialog(error: error)
            }
        })

        return composition
    }

    func mergeAudioAssets(recordAsset: AVAsset, mediaAsset: AVAsset) -> AVMutableComposition {
        let composition = AVMutableComposition()
        var maxTimeRange: CMTimeRange!

        recordAsset.tracks(withMediaType: .audio).forEach({ track in
            guard let compositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
                fatalError()
            }

            if maxTimeRange == nil || track.timeRange.duration > maxTimeRange.duration {
                maxTimeRange = track.timeRange
            }

            do {
                try compositionTrack.insertTimeRange(track.timeRange, of: track, at: kCMTimeZero)
            } catch let error {
                self.presentErrorDialog(error: error)
            }
        })

        mediaAsset.tracks(withMediaType: .audio).forEach({ track in
            guard let compositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
                fatalError()
            }
            do {
                try compositionTrack.insertTimeRange(maxTimeRange, of: track, at: kCMTimeZero)
            } catch let error {
                self.presentErrorDialog(error: error)
            }
        })

        return composition
    }

    func reset(_ callback: @escaping () -> Void) {
        if let recordsPlayer = self.recordsPlayer {
            recordsPlayer.seek(to: 0, completionHandler: { _ in
                self.mediaPlayer?.seek(to: 0, completionHandler: { _ in
                    callback()
                })
            })
        } else {
            self.mediaPlayer?.seek(to: 0, completionHandler: { _ in
                callback()
            })
        }
    }

    func save() {
        player?.stop()
        mediaPlayer?.pause()
        recordsPlayer?.pause()
        btnPlayPause.isSelected = false

        didTapCloseNotepadButton(self)

        viewActions.fadeOut(completion: { _ in
            self.viewActions.isHidden = true
        })
        viewMixer.popOut(completion: { _ in
            self.viewMixer.isHidden = true
        })

        do {
            try player?.reloadFile()
        } catch let error {
            presentErrorDialog(error: error)
        }

        player?.audioFile.exportAsynchronously(name: "track\(count)", baseDir: .temp, exportFormat: .m4a, callback: { (audioFile, error) in
            if let error = error {
                self.presentErrorDialog(error: error)
                return
            }
            guard let url = audioFile?.url else {
                return
            }
            let vocalAsset = AVURLAsset(url: url)

            let composition = self.merge(vocalAsset: vocalAsset)

            var outputUrl: URL!
            do {
                outputUrl = try FileManager.default.tempFolderForProcessingAudio()
            } catch let error {
                self.presentErrorDialog(error: error)
                return
            }

            guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) else {
                fatalError()
            }
            exportSession.outputFileType = .m4a
            exportSession.outputURL = outputUrl
            exportSession.shouldOptimizeForNetworkUse = true
            exportSession.exportAsynchronously {
                DispatchQueue.main.async {
                    switch exportSession.status {
                    case .completed:
                        let recordAsset = AVURLAsset(url: outputUrl)

                        guard let mediaAsset = self.mediaPlayer?.asset else {
                            return
                        }

                        let composition = self.mergeAudioAssets(recordAsset: recordAsset, mediaAsset: mediaAsset)

                        var outputUrl: URL!
                        do {
                            outputUrl = try FileManager.default.tempFolderForProcessingSong()
                        } catch let error {
                            self.presentErrorDialog(error: error)
                            return
                        }

                        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) else {
                            fatalError()
                        }
                        let params = AVMutableAudioMixInputParameters(track: composition.tracks.last)
                        params.setVolume(self.mediaPlayer?.volume ?? 0.5, at: kCMTimeZero)
                        let audioMix = AVMutableAudioMix()

                        audioMix.inputParameters = [params]

                        exportSession.audioMix = audioMix
                        exportSession.outputFileType = .m4a
                        exportSession.outputURL = outputUrl
                        exportSession.shouldOptimizeForNetworkUse = true
                        exportSession.exportAsynchronously {
                            DispatchQueue.main.async {
                                switch exportSession.status {
                                case .completed:
                                    self.recordsPlayer?.stop()
                                    self.recordsPlayer = nil

                                    let storyboard = UIStoryboard(name: "VideoCapture", bundle: Bundle.main)
                                    guard let viewController = storyboard.instantiateViewController(withIdentifier: "SaveMediaViewController") as? SaveMediaViewController else {
                                        fatalError("couldn't instantiate SaveMediaViewController")
                                    }

                                    if let song = self.media as? Song, song.amOwner {
                                        viewController.media = song
                                        viewController.base = song.beat
                                    } else {
                                        viewController.base = self.media
                                    }

                                    viewController.url = outputUrl
                                    viewController.delegate = self

                                    let navigationController = UINavigationController(rootViewController: viewController)
                                    navigationController.navigationBar.isHidden = true
                                    navigationController.modalPresentationStyle = .overFullScreen

                                    self.navigationController?.present(navigationController, animated: false, completion: nil)
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
        })
    }

    func stopMonitoring() {
        btnMonitor.isSelected = false
        pulsator.stop()
        micBooster?.gain = 0
    }
    
    func output(through port: AVAudioSessionPortOverride) {
        guard !AKSettings.headPhonesPlugged else {
            return
        }
        
        do {
            try session.overrideOutputAudioPort(port)
        } catch let error {
            self.presentErrorDialog(error: error)
        }
    }
    
    @objc func didTapView(_ gesture: UIGestureRecognizer) {
        guard gesture.state == .ended else {
            return
        }

        view.endEditing(true)
    }

    @objc func keyboardWillShow(_ notification: Notification) {
        guard let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size else {
            return
        }
        guard let rate = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }

        toolbarBottomLayoutConstraint.constant = keyboardSize.height - (tabBarController?.tabBar.frame.height ?? 0)

        UIView.animate(withDuration: rate, animations: { [weak self] in
            self?.view.layoutIfNeeded()
        })
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        guard let rate = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }

        toolbarBottomLayoutConstraint.constant = 0

        UIView.animate(withDuration: rate, animations: { [weak self] in
            self?.view.layoutIfNeeded()
        })
    }

    @IBAction func didTapSaveLyricsButton(_ sender: Any) {
        let alertController = UIAlertController(title: NSLocalizedString("Name Your Lyrics", comment: "Studio"), message: nil, preferredStyle: .alert)
        alertController.addTextField(configurationHandler: { textField in
            textField.placeholder = NSLocalizedString("Name Your Lyrics", comment: "Studio")
            textField.text = self.lyric.title
        })
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Dialog action"), style: .default, handler: { action in
            self.lyric.title = alertController.textFields?.first?.text
            self.lyric.body = self.txtLyrics.text

            if self.lyric.uuid != nil {
                LyricsClient.shared.update(lyric: self.lyric, success: { lyric in
                    self.lyric = lyric
                }, failure: { error in
                    self.presentErrorDialog(error: error)
                })
            } else {
                LyricsClient.shared.create(lyric: self.lyric, success: { lyric in
                    self.lyric = lyric
                }, failure: { error in
                    self.presentErrorDialog(error: error)
                })
            }
        }))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Dialog action"), style: .cancel, handler: nil))

        present(alertController, animated: true, completion: nil)
    }

    @IBAction func didTapChooseLyricsButton(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Studio", bundle: Bundle.main)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "LyricsTableViewController") as? LyricsTableViewController else {
            fatalError("couldn't instantiate LyricsTableViewController")
        }

        viewController.delegate = self

        navigationController?.pushViewController(viewController, animated: true)
    }

    @IBAction func didTapCloseNotepadButton(_ sender: Any) {
        toolbarBottomLayoutConstraint.constant = -180
        NotificationCenter.default.removeObserver(self)

        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            self?.view.layoutIfNeeded()
        }) { _ in
            self.lyricsView.isHidden = true
        }
        view.endEditing(true)
    }

    @IBAction func didTapMenuButton(_ sender: Any) {
        menuVC.openMenu()
        menuView.isUserInteractionEnabled = true;
    }

    @IBAction func didTapChooseBeatButton(_ sender: Any) {
        if state != .recording {
            let storyboard = UIStoryboard(name: "ARUser", bundle: Bundle.main)
            guard let viewController = storyboard.instantiateViewController(withIdentifier: "MyBeatsViewController") as? MyBeatsViewController else {
                return
            }

            viewController.delegate = self

            navigationController?.pushViewController(viewController, animated: true)
        }
    }

    @IBAction func didTapLyricButton(_ sender: Any) {
        lyricsView.isHidden = false
        toolbarBottomLayoutConstraint.constant = 0

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)

        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            self?.view.layoutIfNeeded()
        })
    }

    // TODO: implement 2017-12-13
    @IBAction func didTapMonitorButton(_ sender: Any) {

        if btnMonitor.isSelected {
            stopMonitoring()
        } else {
            if AKSettings.headPhonesPlugged {
                if let micBooster = micBooster {
                    pulsator.start()
                    micBooster.gain = 1
                    btnMonitor.isSelected = true
                } else {
                    view.makeToast(NSLocalizedString("The mic is not ready... please try again.", comment: "Studio"), duration: 3, position: .center)
                }
                micBooster?.gain = 1
            } else {
                view.makeToast(NSLocalizedString("You must wear your headphones in order to monitor.", comment: "Studio"), duration: 3, position: .center)
            }
        }

    }

    @IBAction func didTapRecordButton(_ sender: Any) {
        switch state {
        case .readyToRecord:
            guard media != nil else {
                showNoBeatWarning()
                return
            }

            state = .recording

            preparingToRecord = true

            sldLocalVolume.value = 0.5
            mediaPlayer?.volume = 0.5

            reset {
                self.showRecordingCountDown()
            }
        case .recording:
            state = .readyToPlay

            recorder?.stop()
            mediaPlayer?.pause()
            recordsPlayer?.pause()
            btnPlayPause.isSelected = false
            uploadInBackground = false

            AKSettings.defaultToSpeaker = false

            output(through: .speaker)
            stopMonitoring()

//            DispatchQueue.main.async {
            
            let d = DispatchTime.now() + Double(Int64(0.5 * Float(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: d) {
                do {
                    try self.player?.reloadFile()
                } catch let error {
                    self.presentErrorDialog(error: error)
                }
                self.stopSpinAnimation()
                self.animateRecordingStopped()
                self.reset {
                    self.state = .playing
                    self.mediaPlayer?.play()
                    self.recordsPlayer?.play()
                    self.player?.play()
                }
            }
        case .loading, .readyToPlay, .playing:
            break
        }
    }

    @IBAction func onRecordVideoButton(_ sender: Any) {
        let storyboard = UIStoryboard(name: "VideoCapture", bundle: Bundle.main)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "CaptureVideoViewController") as? CaptureVideoViewController else {
            fatalError("couldn't instantiate CaptureVideoViewController")
        }

        viewController.delegate = self

        let navigationController = UINavigationController(rootViewController: viewController)

        self.present(navigationController, animated: true, completion: nil)
    }

    @IBAction func didTapPlayPauseButton(_ sender: Any) {
        btnPlayPause.isSelected = !btnPlayPause.isSelected

        if btnPlayPause.isSelected {
            mediaPlayer?.play()
            recordsPlayer?.play()
            player?.play()
        } else {
            mediaPlayer?.pause()
            recordsPlayer?.pause()
            player?.pause()
            if state == .recording {
                didTapRecordButton(self)
            }
        }
    }

    @IBAction func sliderProgressValueDidChange(_ sender: Any) {
        btnPlayPause.isSelected = false

        if state == .readyToRecord {
            let position = Double(sldProgress.value)

            if let recordsPlayer = recordsPlayer {
                recordsPlayer.seek(to: position) { _ in
                    self.mediaPlayer?.seek(to: position) { _ in
                        self.mediaPlayer?.play()
                        self.recordsPlayer?.play()
                        self.btnPlayPause.isSelected = true
                    }
                }
            } else {
                mediaPlayer?.seek(to: position) { _ in
                    self.mediaPlayer?.play()
                    self.btnPlayPause.isSelected = true
                }
            }
        }
    }

    @IBAction func sliderVolumeValueDidChange(_ sender: Any) {
        mediaPlayer?.volume = sldLocalVolume.value
    }

    @IBAction func didTapMixerOptionsButton(_ sender: UIButton) {
        if viewActions.isHidden {
            viewActions.isHidden = false
            viewActions.fadeIn()
        }

        player?.stop()
        recorder?.stop()
        mediaPlayer?.pause()
        recordsPlayer?.pause()
        btnPlayPause.isSelected = false
    }

    @IBAction func didTapMixerSaveButton(_ sender: UIButton) {
        save()
    }

    @IBAction func didTapPreviewEditSaveButton(_ sender: UIButton) {
        viewMixer.popIn()
        viewActions.fadeOut(completion: { _ in
            self.viewActions.isHidden = true
        })

        player?.start()
        mediaPlayer?.play()
        recordsPlayer?.play()
        btnPlayPause.isSelected = true
    }

    @IBAction func didTapRecordAVideoButton(_ sender: UIButton) {
        uploadInBackground = true
        save()
    }

    @IBAction func didTapAddAnotherTrackButton(_ sender: UIButton) {
        do {
            try player?.reloadFile()
        } catch let error {
            self.presentErrorDialog(error: error)
        }

        player?.audioFile.exportAsynchronously(name: "track\(count)", baseDir: .temp, exportFormat: .m4a, callback: { (audioFile, error) in
            if let error = error {
                self.presentErrorDialog(error: error)
                return
            }
            guard let url = audioFile?.url else {
                return
            }
            let vocalAsset = AVURLAsset(url: url)

            let composition = self.merge(vocalAsset: vocalAsset)

            var outputUrl: URL!
            do {
                outputUrl = try FileManager.default.tempFolderForProcessingAudio()
            } catch let error {
                self.presentErrorDialog(error: error)
                return
            }

            guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) else {
                fatalError()
            }
            exportSession.outputFileType = .m4a
            exportSession.outputURL = outputUrl
            exportSession.shouldOptimizeForNetworkUse = true
            exportSession.exportAsynchronously {
                DispatchQueue.main.async {
                    switch exportSession.status {
                    case .completed:
                        self.count += 1
                        self.recordsPlayer?.stop()
                        self.recordsPlayer = MediaPlayer(url: outputUrl)

                        do {
                            try self.recorder?.reset()
                        } catch let error {
                            self.presentErrorDialog(error: error)
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
        })
    }

    @IBAction func didTapReRecordVocals(_ sender: UIButton) {

        viewMixer.popOut(completion: { _ in
            self.viewMixer.isHidden = true
        })
        viewActions.fadeOut(completion: { _ in
            self.viewActions.isHidden = true
        })

        player?.stop()
        mediaPlayer?.pause()
        recordsPlayer?.pause()
        btnPlayPause.isSelected = false

        recorder?.stop()
        do {
            try recorder?.reset()
        } catch let error {
            self.presentErrorDialog(error: error)
        }
        state = .readyToRecord

        didTapRecordButton(btnRecord)
    }

    @IBAction func didTapDeleteButton(_ sender: UIButton) {
        viewActions.fadeOut(completion: { _ in
            self.viewActions.isHidden = true
        })
        viewMixer.popOut(completion: { _ in
            self.viewMixer.isHidden = true
        })

        player?.stop()
        mediaPlayer?.pause()
        recordsPlayer?.stop()
        recordsPlayer = nil
        btnPlayPause.isSelected = false

        recorder?.stop()
        do {
            try recorder?.reset()
        } catch let error {
            self.presentErrorDialog(error: error)
        }
        state = .readyToRecord
    }
}

extension StudioViewController: TrimAudioViewControllerDelegate {
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

extension StudioViewController: CountdownLabelDelegate {
    func showRecordingCountDown() {
        self.lblCountdown.setCountDownTime(minutes: 3)
        self.lblCountdown.fadeIn(duration: 0.1, delay: 0) { _ in
            if !AKSettings.headPhonesPlugged {
                self.view.makeToast(NSLocalizedString("No Headphones, No Problem: Record your vocals as if you are on a phone call.", comment: "Studio"), duration: 3, position: .center)
            }
            self.lblCountdown.start()
        }
    }

    // CountDown Delegate
    func countdownFinished() {
        let d = DispatchTime.now() + Double(Int64(0.5 * Float(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: d) {
            self.lblCountdown.fadeOut(duration: 0.1, delay: 0) { _ in
                self.startSpinAnimation()
                self.animateRecordingStarted()
                
                self.output(through: .none)
                
                self.mediaPlayer?.play()
                self.recordsPlayer?.play()
                self.btnPlayPause.isSelected = true
            }
        }
    }
}

// TODO: refactor (dry)
extension StudioViewController: CaptureVideoViewControllerDelegate {
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

// TODO: refactor (dry)
extension StudioViewController: VideoFiltersViewControllerDelegate {
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

extension StudioViewController: AddVocalsToBeatDelegate {
    func didSelectAddVocalsToBeat(viewController: MyBeatsViewController, beat: Beat) {
        self.navigationController?.popViewController(animated: true)
        self.media = beat
    }

    func didCancel(viewController: MyBeatsViewController) {
        self.navigationController?.popViewController(animated: true)
    }
}

extension StudioViewController: SaveMediaViewControllerDelegate {
    func didConfirm(viewController: SaveMediaViewController, media: Media) {
        viewController.dismiss(animated: true) {
            self.state = .readyToRecord
            self.reset {
                self.sldProgress.setValue(0, animated: true)
                self.lblBeatDuration.text = 0.0.durationString()
            }
            self.mediaPlayer = nil
            self.recordsPlayer = nil
            self.media = nil

            // TODO: 2018-04-17 refactor
            if let song = media as? Song {
                if self.uploadInBackground {
                    let storyboard = UIStoryboard(name: "ARUser", bundle: Bundle.main)
                    guard let viewController = storyboard.instantiateViewController(withIdentifier: "TrimAudioViewController") as? TrimAudioViewController else {
                        fatalError("couldn't instantiate TrimAudioViewController")
                    }

                    viewController.uploadingInBackground = true
                    viewController.media = media
                    viewController.delegate = self

                    self.present(viewController, animated: true, completion: nil)

                    DispatchQueue.global(qos: .background).async {
                        if let uuid = song.uuid {
                            SongsClient.shared.upload(song: song, success: { _ in
                                SongsClient.shared.delete(uuid: uuid, success: {
                                    // Do nothing for now...
                                }, failure: { error in
                                    self.presentErrorDialog(error: error)
                                })
                            }, failure: { error in
                                self.presentErrorDialog(error: error)
                            })
                        } else {
                            SongsClient.shared.upload(song: song, success: { _ in
                                // Do nothing for now...
                            }, failure: { error in
                                self.presentErrorDialog(error: error)
                            })
                        }
                    }
                } else {
                    self.view.loading(with: NSLocalizedString("Great Work! We are Saving your New Song!", comment: "Studio"))
                    
                    if let uuid = song.uuid {
                        SongsClient.shared.upload(song: song, success: { _ in
                            SongsClient.shared.delete(uuid: uuid, success: { // delete old one only after upload the new one
                                self.view.loaded()
                                //Go to creations tab
                                self.parent?.tabBarController?.selectedIndex = 3
                                
                                // TODO: 2018-02-07 refactor find better way
                                guard let creationsViewController = (self.tabBarController?.viewControllers?[3] as? UINavigationController)?.viewControllers.first as? CreationsViewController else {
                                    return
                                }
                                creationsViewController.mode = .song
                                creationsViewController.loadMedia()
                            }, failure: { (error) in
                                self.presentErrorDialog(error: error)
                            })
                        }, failure: { error in
                            self.presentErrorDialog(error: error)
                        })
                    } else {
                        SongsClient.shared.upload(song: song, success: { _ in
                            self.view.loaded()
                            //Go to creations tab
                            self.parent?.tabBarController?.selectedIndex = 3
                            
                            // TODO: 2018-02-07 refactor find better way
                            guard let creationsViewController = (self.tabBarController?.viewControllers?[3] as? UINavigationController)?.viewControllers.first as? CreationsViewController else {
                                return
                            }
                            creationsViewController.mode = .song
                            creationsViewController.loadMedia()
                        }, failure: { error in
                            self.presentErrorDialog(error: error)
                        })
                    }
                }
            } else if let video = media as? Video {
                self.view.loading(with: NSLocalizedString("Looks good! Let us Save it Now!", comment: "Studio"))
                VideosClient.shared.upload(video: video, success: { _ in
                    self.view.loaded()
                    //Go to creations tab
                    self.parent?.tabBarController?.selectedIndex = 3

                    // TODO: 2018-02-07 refactor find better way
                    guard let creationsViewController = (self.tabBarController?.viewControllers?[3] as? UINavigationController)?.viewControllers.first as? CreationsViewController else {
                        return
                    }
                    creationsViewController.mode = .video
                }, failure: { error in
                    self.presentErrorDialog(error: error)
                })
            }
        }
    }
    
    func didCancel(viewController: SaveMediaViewController) {
        viewController.dismiss(animated: true, completion: nil)
        viewMixer.popIn()
    }
}

extension StudioViewController: MediaPlayerDelegate {
    func onReadyToPlay(player: MediaPlayer) {
        if player == self.mediaPlayer {
            if !CMTIME_IS_INDEFINITE(player.duration) {
                sldProgress.maximumValue = Float(player.duration.seconds)
            }

            btnPlayPause.isUserInteractionEnabled = true
            sldProgress.isUserInteractionEnabled = true
        } else if player == self.recordsPlayer {
            DispatchQueue.main.async {
                self.viewActions.fadeOut(completion: { _ in
                    self.viewActions.isHidden = true
                })
                self.viewMixer.popOut(completion: { _ in
                    self.viewMixer.isHidden = true
                })
                self.state = .readyToRecord
                self.didTapRecordButton(self.btnRecord)
            }
        }
    }

    func onPeriodicTimeObserver(player: MediaPlayer, time: CMTime) {
        guard player == self.mediaPlayer else {
            return
        }
        sldProgress.setValue(Float(time.seconds), animated: true)
        lblBeatDuration.text = time.seconds.durationString()

        if preparingToRecord && time.value != 0 {
            preparingToRecord = false
            do {
                try self.recorder?.record()
                print("AppDebug", "Did start Recording!", time.value)
            } catch let error {
                self.presentErrorDialog(error: error)
            }
        }
    }

    func didPlayToEndTime(player: MediaPlayer) {
        if player == self.mediaPlayer || (state == .playing && player == self.recordsPlayer && ((self.player?.duration ?? 0) <= (self.recordsPlayer?.duration.seconds ?? 0))) { // TODO: implement 2018-01-03 end recording session
            reset {
                self.player?.play()
                self.mediaPlayer?.play()
                self.recordsPlayer?.play()
            }
        }
    }

    func didStartPlaying(player: MediaPlayer) {
    }

    func onFailure(error: Error) {
        self.presentErrorDialog(error: error)
    }
}

extension StudioViewController: MyStudioPopoverDelegate {
    func myStudioButtonClicked(withIndex index: Int) {
        switch index {
        case 1:
            let storyboard = UIStoryboard(name: "Creations", bundle: Bundle.main)
            guard let viewController = storyboard.instantiateViewController(withIdentifier: "CreationsViewController") as? CreationsViewController else {
                fatalError("couldn't instantiate CreationsViewController")
            }
            viewController.showBack = true
            viewController.mode = .song
            navigationController?.pushViewController(viewController, animated: true)
        case 2:
            let storyboard = UIStoryboard(name: "Creations", bundle: Bundle.main)
            guard let viewController = storyboard.instantiateViewController(withIdentifier: "CreationsViewController") as? CreationsViewController else {
                fatalError("couldn't instantiate CreationsViewController")
            }
            viewController.showBack = true
            navigationController?.pushViewController(viewController, animated: true)
        case 3:
            didTapChooseBeatButton(self)
        case 4:
            let storyboard = UIStoryboard(name: "Studio", bundle: Bundle.main)
            guard let viewController = storyboard.instantiateViewController(withIdentifier: "LyricsTableViewController") as? LyricsTableViewController else {
                fatalError("couldn't instantiate LyricsTableViewController")
            }

            viewController.delegate = self

            navigationController?.pushViewController(viewController, animated: true)
        case 5:
            let storyboard = UIStoryboard(name: "Music", bundle: Bundle.main)
            guard let viewController = storyboard.instantiateViewController(withIdentifier: "AllProducersViewController") as? AllProducersViewController else {
                fatalError("couldn't instantiate LyricsTableViewController")
            }
            navigationController?.pushViewController(viewController, animated: true)
        default:
            print("default")
        }
    }
}

extension StudioViewController: LyricsTableViewControllerDelegate {
    func didSelectLyric(viewController: LyricsTableViewController, lyric: Lyric) {
        navigationController?.popViewController(animated: true)

        self.lyric = lyric
        self.txtLyrics.text = lyric.body
    }
}
