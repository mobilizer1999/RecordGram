//
//  MediaDownloaderViewController.swift
//  RecordGram
//
//  Created by Hugo Prione on 20/11/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import RPCircularProgress

protocol MediaDownloaderViewControllerDelegate {
    func didDownloadMedia(viewController: MediaDownloaderViewController, media: Media, url: URL)
}

class MediaDownloaderViewController: ModalViewController, ErrorHandler {

    @IBOutlet weak var imgBeat: UIImageView!
    @IBOutlet weak var lblBeatName: UILabel!
    @IBOutlet weak var lblProducerName: UILabel!
    @IBOutlet weak var lblGenre: UILabel!
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var circularProgress: RPCircularProgress! {
        didSet {
            circularProgress.enableIndeterminate()
        }
    }
    
    var media: Media!
    var delegate: MediaDownloaderViewControllerDelegate?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        lblBeatName.text = media.name

        if let song = media as? Song {
            let username = song.beat?.producer?.name ?? NSLocalizedString("Unknown", comment: "Unknown username")

            lblProducerName.text = NSLocalizedString("Prod by: %@", comment: "Download media")
            imgBeat.kf.setImage(with: media.image, placeholder: #imageLiteral(resourceName:"profile_placeholder"), options: nil, progressBlock: nil, completionHandler: nil)
        } else if let video = media as? Video {
            let username = video.beat?.producer?.name ?? NSLocalizedString("Unknown", comment: "Unknown username")

            lblProducerName.text = NSLocalizedString("Prod by: %@", comment: "Download media")
            imgBeat.kf.setImage(with: media.image, placeholder: #imageLiteral(resourceName:"profile_placeholder"), options: nil, progressBlock: nil, completionHandler: nil)
        } else if let beat = media as? Beat {
            let username = beat.producer?.name ?? NSLocalizedString("Unknown", comment: "Unknown username")

            lblProducerName.text = NSLocalizedString("Prod by: %@", comment: "Download media")
            imgBeat.kf.setImage(with: beat.producer?.profilePicture, placeholder: #imageLiteral(resourceName:"profile_placeholder"), options: nil, progressBlock: nil, completionHandler: nil)
        }

        lblGenre.text = media.genre?.name

        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        var destinationUrl: URL!

        guard let url = media.url else {
            fatalError()
        }

        do {
            destinationUrl = try FileManager.default.folderPath(forMedia: media)
        } catch let error {
            presentErrorDialog(error: error)
            return
        }

        var uuid = ""
        if let song = media as? Song {
            uuid = song.beat?.uuid ?? ""
        } else if let video = media as? Video {
            uuid = video.beat?.uuid ?? ""
        } else if let beat = media as? Beat {
            uuid = beat.uuid ?? ""
        }

        BeatsClient.shared.trackDownload(uuid: uuid, success: {
            BeatsClient.shared.download(url: url, destinationUrl: destinationUrl, progress: { value in
                
            }, success: { url in
                self.delegate?.didDownloadMedia(viewController: self, media: self.media, url: url)
            }, failure: { error in
                self.presentErrorDialog(error: error)
            })
        }, failure: { error in
            self.presentErrorDialog(error: error)
        })
    }
}

extension UIViewController {

    func download(_ media: Media) {
        let storyboard = UIStoryboard(name: "ARUser", bundle: Bundle.main)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "MediaDownloaderViewController") as? MediaDownloaderViewController else {
            fatalError("couldn't instantiate MediaDownloaderViewController")
        }

        viewController.media = media
        viewController.delegate = self as? MediaDownloaderViewControllerDelegate
        viewController.modalPresentationStyle = .overFullScreen

        self.present(viewController, animated: true)
    }
}
