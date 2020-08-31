//
//  MediaOptionsViewController.swift
//  RecordGram
//
//  Created by Hugo Prione on 21/11/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit

protocol MediaOptionsViewControllerDelegate {
    func didSelectAddVocalsToMedia(viewController: MediaOptionsViewController, media: Media)
}

class MediaOptionsViewController: ModalViewController {

    var media: Media!
    var delegate: MediaOptionsViewControllerDelegate?

    @IBOutlet weak var btnAddVocalsToMedia: UIButton!
    @IBOutlet weak var btnShootVideo: UIButton!
    @IBOutlet weak var btnClose: UIButton!

    @IBAction func didTapAddVocalsToMediaButton(_ sender: Any) {
        close {
            self.delegate?.didSelectAddVocalsToMedia(viewController: self, media: self.media)
        }
    }

    @IBAction func didTapShootVideoButton(_ sender: Any) {
        close {
            if let viewController = self.delegate as? UIViewController {
                viewController.openTrimAudio(for: self.media)
            }
        }
    }
}

extension UIViewController {

    func openBeatOptions(for media: Media) {
        let storyboard = UIStoryboard(name: "ARUser", bundle: Bundle.main)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "BeatOptionsViewController") as? MediaOptionsViewController else {
            fatalError("couldn't instantiate BeatOptionsViewController")
        }

        viewController.media = media
        viewController.delegate = self as? MediaOptionsViewControllerDelegate
        viewController.modalPresentationStyle = .overFullScreen

        self.present(viewController, animated: true)
    }
}
