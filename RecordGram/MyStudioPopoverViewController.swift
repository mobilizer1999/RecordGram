//
//  MyStudioPopoverViewController.swift
//  RecordGram
//
//  Created by Dewayne Perry on 10/6/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.

import UIKit


protocol MyStudioPopoverDelegate {
    func myStudioButtonClicked(withIndex index: Int)
}

class MyStudioPopoverViewController: UIViewController {
    var homeVC: HomeViewController!
    var delegate: MyStudioPopoverDelegate?
    @IBOutlet weak var producers: UIView!
    @IBOutlet weak var beats: UIView!
    @IBOutlet weak var lyrics: UIView!
    @IBOutlet weak var songs: UIView!
    @IBOutlet weak var videos: UIView!
    @IBOutlet weak var base: UIView!
    let areaToNotDismiss  = 11
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        setupBaseView()
        setupProducersView()
        setupBeatsView()
        setupLyricsView()
        setupSongsView()
        setupVideosView()
        addBlur()
    }
    
    func setupBaseView() {
        base.tag = areaToNotDismiss
        base.backgroundColor = UIColor.clear
        base.layer.borderColor = UIColor.white.cgColor
        base.layer.borderWidth = 1
        base.layer.cornerRadius = 8
        base.clipsToBounds = true
    }
    
    func setupProducersView() {
        producers.tag = areaToNotDismiss
        producers.backgroundColor = UIColor.clear
    }
    
    func setupBeatsView() {
        beats.tag = areaToNotDismiss
        beats.backgroundColor = UIColor.clear
    }
    
    func setupLyricsView() {
        lyrics.tag = areaToNotDismiss
        lyrics.backgroundColor = UIColor.clear
    }
    
    func setupSongsView() {
        songs.tag = areaToNotDismiss
        songs.backgroundColor = UIColor.clear
    }
    
    func setupVideosView() {
        videos.tag = areaToNotDismiss
        videos.backgroundColor = UIColor.clear
    }
    
    func addBlur() {
        let blur = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: blur)
        blurView.frame = base.bounds
        base.addSubview(blurView)
        base.sendSubview(toBack: blurView)
        blurView.alpha = 0.9
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.first?.view?.tag != areaToNotDismiss {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func buttonClicked(_ sender: UIButton) {
        self.dismiss(animated: true) {
            self.delegate?.myStudioButtonClicked(withIndex: sender.tag)
        }
    }
    
}
