//
//  MySongOptionsViewController.swift
//  RecordGram
//
//  Created by Hugo Prione on 27/11/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit

protocol MySongOptionsViewControllerDelegate {
    func didTapShootVideoButton(song: Song, viewController: MySongOptionsViewController)
    func didTapPlaySongButton(song: Song, viewController: MySongOptionsViewController)
    func didTapShareSongButton(song: Song, viewController: MySongOptionsViewController)
    func didTapMakePublicButton(song: Song, viewController: MySongOptionsViewController)
    func didTapUpdateSongInfoButton(song: Song, viewController: MySongOptionsViewController)
    func didTapAddVocalsButton(song: Song, viewController: MySongOptionsViewController)
    func didTapDeleteSongButton(song: Song, viewController: MySongOptionsViewController)
    func didTapCloseButton(song: Song, viewController: MySongOptionsViewController)
}

class MySongOptionsViewController: UIViewController {
    var song: Song!
    var delegate: MySongOptionsViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - IBActions
    
    @IBAction func didTapShootVideoButton(_ sender: Any) {
        delegate?.didTapShootVideoButton(song: song, viewController: self)
    }
    
    @IBAction func didTapPlaySongButton(_ sender: Any) {
        delegate?.didTapPlaySongButton(song: song, viewController: self)
    }
    
    @IBAction func didTapShareSongButton(_ sender: Any) {
        delegate?.didTapShareSongButton(song: song, viewController: self)
    }
    
    @IBAction func didTapMakePublicButton(_ sender: Any) {
        delegate?.didTapMakePublicButton(song: song, viewController: self)
    }
    
    @IBAction func didTapUpdateSongInfoButton(_ sender: Any) {
        delegate?.didTapUpdateSongInfoButton(song: song, viewController: self)
    }
    
    @IBAction func didTapAddVocalsButton(_ sender: Any) {
        delegate?.didTapAddVocalsButton(song: song, viewController: self)
    }
    
    @IBAction func didTapDeleteSongButton(_ sender: Any) {
        delegate?.didTapDeleteSongButton(song: song, viewController: self)
    }
    
    @IBAction func didTapCloseButton(_ sender: Any) {
        delegate?.didTapCloseButton(song: song, viewController: self)
    }
}
