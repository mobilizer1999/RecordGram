//
//  BeatTableViewCell.swift
//  RecordGram
//
//  Created by Nicolas Gonzalez on 3/30/18.
//  Copyright © 2018 Meridian Inc. All rights reserved.
//

import UIKit
import RPCircularProgress

class BeatTableViewCell: UITableViewCell {

    var downloading = false
    var beat: Beat?

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var beatSavedImage: UIImageView!
    @IBOutlet weak var priceButton: UIButton!
    @IBOutlet weak var downloadProgress: RPCircularProgress! {
        didSet {
            downloadProgress.enableIndeterminate()
        }
    }

    @IBAction func onButtonTap() {
        if let beat = beat, let parentViewController = parentViewController {
            if beat.needToPurchase {
                if beat.canBuy {
                    if let uuid = beat.uuid {
                        parentViewController.view.loading(with: NSLocalizedString("Making Coins Move!", comment: "Coins"))
                        BeatsClient.shared.purchase(uuid: uuid, success: {
                            UserClient.shared.invalidateUser()
                            UserClient.shared.get("credits") { credits in
                                parentViewController.view.loaded()
                                self.download()
                            }
                        }, failure: { error in
                            parentViewController.view.loaded()
                            print("❗", error.localizedDescription)
                        })
                    }
                } else {
                    parentViewController.openCoinsPopover()
                }
            } else {
                download()
            }
        }
    }

    private func download() {
        if let beat = beat, let url = beat.url, let uuid = beat.uuid,
           let parentViewController = parentViewController {

            downloading = true

            priceButton.isHidden = true
            downloadProgress.isHidden = false

            do {

                let destinationUrl = try FileManager.default.folderPath(forMedia: beat)

                BeatsClient.shared.trackDownload(uuid: uuid, success: {
                    BeatsClient.shared.download(url: url, destinationUrl: destinationUrl, progress: { value in
                        
                    }, success: { url in
                        self.setup(with: beat)
                        parentViewController.openBeatOptions(for: beat)
                        self.downloading = false
                        self.downloadProgress.isHidden = true
                    }, failure: { error in
                        self.handleError(error)
                    })
                }, failure: { error in
                    self.handleError(error)
                })
            } catch let error {
                handleError(error)
            }
        }
    }

    private func handleError(_ error: Error) {
        if let parentViewController = parentViewController as? ErrorHandler {
            parentViewController.presentErrorDialog(error: error)
        }

        downloading = false

        priceButton.isHidden = false
        downloadProgress.isHidden = true
    }

    func setup(with beat: Beat) {
        self.beat = beat

        if let name = beat.name {
            titleLabel.text = name
        } else {
            titleLabel.text = "███"
        }
        if let url = try? FileManager.default.folderPath(forMedia: beat),
           FileManager.default.fileExists(atPath: url.path) {
            priceButton.isHidden = true
            beatSavedImage.isHidden = false
        } else {
            priceButton.isHidden = false
            beatSavedImage.isHidden = true
            if let price = beat.price, price != 0 {
                priceButton.setTitle(String(format: NSLocalizedString("%d COINS", comment: "Price in Coins"), price), for: .normal)
            } else {
                priceButton.setTitle(NSLocalizedString("FREE", comment: "Price in Coins"), for: .normal)
            }
        }
    }

    func clear() {
        beat = nil
        titleLabel.text = "███"
        priceButton.isHidden = false
        beatSavedImage.isHidden = true
    }
}
