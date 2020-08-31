//
//  PlayerView.swift
//  RecordGram
//
//  Created by Hugo Prione on 16/11/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import AVFoundation

class PlayerView: UIView {
    override class var layerClass: AnyClass {
        get {
            return AVPlayerLayer.self
        }
    }
    
    var playerLayer: AVPlayerLayer {
        get {
            return self.layer as! AVPlayerLayer
        }
    }
    
    var player: AVPlayer? {
        get {
            return self.playerLayer.player
        }
        set {
            self.playerLayer.player = newValue
        }
    }
    
    var fillMode: String {
        get {
            return self.playerLayer.videoGravity.rawValue
        }
        set {
            self.playerLayer.videoGravity = AVLayerVideoGravity(rawValue: newValue)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.playerLayer.backgroundColor = UIColor.black.cgColor
        self.playerLayer.fillMode = AVLayerVideoGravity.resizeAspect.rawValue
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.playerLayer.backgroundColor = UIColor.black.cgColor
        self.playerLayer.fillMode = AVLayerVideoGravity.resizeAspect.rawValue
    }
    
    deinit {
        self.player?.pause()
        self.player = nil
    }
}
