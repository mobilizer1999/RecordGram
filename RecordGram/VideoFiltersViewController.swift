//
//  VideoFiltersViewController.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 10/4/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.

import UIKit
import AVFoundation

protocol VideoFiltersViewControllerDelegate {
    func didConfirm(viewController: VideoFiltersViewController, base: Media?, outputUrl: URL)
    func didCancel(viewController: VideoFiltersViewController)
}

class VideoFiltersViewController: UIViewController, ErrorHandler {
    @IBOutlet weak var viewPlayerContainer: UIView!
    @IBOutlet weak var lblFilterName: UILabel!
    @IBOutlet weak var indicatorProgress: UIActivityIndicatorView! {
        didSet {
            indicatorProgress.stopAnimating()
            indicatorProgress.isHidden = true
        }
    }
    
    var url: URL!
    var base: Media?
    var delegate: VideoFiltersViewControllerDelegate?
    
    private var player: MediaPlayer?
    private var availableVideoFilters = MediaPlayer.availableVideoFilters
    private var currentFilter: Int
    
    required init?(coder aDecoder: NSCoder) {
        currentFilter = 0
        
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let leftSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(didSwipeView))
        leftSwipeGesture.direction = .left
        leftSwipeGesture.cancelsTouchesInView = false

        view.addGestureRecognizer(leftSwipeGesture)
        
        let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(didSwipeView))
        rightSwipeGesture.direction = .right
        rightSwipeGesture.cancelsTouchesInView = false
        
        view.addGestureRecognizer(rightSwipeGesture)
    }
    
    @objc func didSwipeView(_ gesture: UISwipeGestureRecognizer) {
        guard gesture.state == .ended else {
            return
        }
        
        switch gesture.direction {
        case .left:
            currentFilter += 1
            if currentFilter >= availableVideoFilters.count {
                currentFilter = 0
            }
            
            let filter = availableVideoFilters[currentFilter]
            
            lblFilterName.text = filter.title
            
            player?.applyVideoFilter(filter: filter)
        case .right:
            currentFilter -= 1
            if currentFilter < 0 {
                currentFilter = availableVideoFilters.count - 1
            }
            
            let filter = availableVideoFilters[currentFilter]
            
            lblFilterName.text = filter.title
            
            player?.applyVideoFilter(filter: filter)
        default: break
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        player = MediaPlayer(url: url)
        player?.delegate = self
        player?.autoPlay = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        player?.seek(to: 0, completionHandler: { (_) in
            self.player?.play()
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player?.stop()
        player = nil
    }
    
    @IBAction func onExitFilterVCButton(_ sender: Any) {
        delegate?.didCancel(viewController: self)
    }
    
    @IBAction func didTapConfirmButton(_ sender: UIButton) {
        player?.pause()
        
        guard let asset = player?.asset else {
            return
        }
        
        indicatorProgress.isHidden = false
        indicatorProgress.startAnimating()
        
        var outputUrl: URL!
        do {
            outputUrl = try FileManager.default.tempFolderForProcessingVideo()
        } catch let error {
            presentErrorDialog(error: error)
            indicatorProgress.isHidden = true
            indicatorProgress.stopAnimating()
            
            return
        }
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            fatalError()
        }
        exportSession.outputFileType = .mp4
        exportSession.outputURL = outputUrl
        exportSession.videoComposition = player?.videoComposition
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                self.indicatorProgress.stopAnimating()
                self.indicatorProgress.isHidden = true
                
                switch exportSession.status {
                case .completed:
                    self.delegate?.didConfirm(viewController: self, base: self.base, outputUrl: outputUrl)
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
}

extension VideoFiltersViewController: MediaPlayerDelegate {
    func onReadyToPlay(player: MediaPlayer) {
        let playerView = PlayerView()
        playerView.frame = viewPlayerContainer.bounds
        
        viewPlayerContainer.addSubview(playerView)
        
        player.playerView = playerView
    }
    
    func onPeriodicTimeObserver(player: MediaPlayer, time: CMTime) {
        // no-op
    }
    
    func didPlayToEndTime(player: MediaPlayer) {
        player.seek(to: 0, completionHandler: { (_) in
            player.play()
        })
    }
    
    func didStartPlaying(player: MediaPlayer){
    }
    
    func onFailure(error: Error) {
        presentErrorDialog(error: error)
    }
}
