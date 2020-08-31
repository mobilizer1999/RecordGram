//
//  MyBeatsViewController.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/9/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import Kingfisher
import PagedArray

protocol AddVocalsToBeatDelegate {
    func didSelectAddVocalsToBeat(viewController: MyBeatsViewController, beat: Beat)
    func didCancel(viewController: MyBeatsViewController)
}

class MyBeatsViewController: UIViewController, ErrorHandler {

    var delegate: AddVocalsToBeatDelegate?

    private lazy var downloadedBeats = BeatComponent(using: UserClient.shared.downloadedBeats)
    private lazy var favoriteBeats = BeatComponent(using: UserClient.shared.likedBeats)

    let placeholder = UIImage(named: "media_placeholder")

    var hideTabs = false

    @IBOutlet weak var tableViewBeats: UITableView!
    @IBOutlet var btnUnlockedBeats: UIButton!
    @IBOutlet var btnFavoritedBeats: UIButton!

    @IBAction func unlockedBeatsBtnPressed(_ sender: Any) {
        btnUnlockedBeats.isSelected = true
        btnFavoritedBeats.isSelected = false
        tableViewBeats.reloadData()
    }

    @IBAction func favoritedBeatsBtnPressed(_ sender: Any) {
        btnUnlockedBeats.isSelected = false
        btnFavoritedBeats.isSelected = true
        tableViewBeats.reloadData()
    }

    @IBAction func unlockNewBeats() {
        if let tabBarController = tabBarController {
            tabBarController.selectedIndex = 1
            if let navigationController = navigationController {
                navigationController.popViewController(animated: false)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationBar()
        btnUnlockedBeats.isSelected = true
        btnFavoritedBeats.isSelected = false

        downloadedBeats.load(tableView: tableViewBeats)
        favoriteBeats.load(tableView: tableViewBeats)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.title = NSLocalizedString("MY BEATS", comment: "My beats")
        if hideTabs {
            noTabs()
        }
    }

    func setupNavigationBar() {
        self.navigationController?.navigationBar.topItem?.title = ""
        
        setupNavigationBarBackButton()
    }
    
    func getSelected() -> BeatComponent {
        if btnUnlockedBeats.isSelected {
            return downloadedBeats
        } else {
            return favoriteBeats
        }
    }
}

// TODO: refactor (organize the flow)
extension MyBeatsViewController: UITableViewDelegate, UITableViewDataSource, UITableViewDataSourcePrefetching {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getSelected().count()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as? MyBeatsTableViewCell else {
            fatalError("couldn't instantiate MyBeatsTableViewCell")
        }

        cell.lblPosition.text = "\(indexPath.row + 1)."

        if let beat = getSelected().item(at: indexPath) {
            if let name = beat.name {
                cell.lblBeatName.text = name
            } else {
                cell.lblBeatName.text = "███"
            }
            if let producerName = beat.producer?.name {
                cell.lblProducerName.text = producerName
            } else {
                cell.lblProducerName.text = "█████"
            }
            if let genreName = beat.genre?.name {
                cell.lblGenreName.text = genreName
            } else {
                cell.lblGenreName.text = "██"
            }
            if let image = beat.image {
                cell.imgProducer.kf.setImage(with: image, placeholder: placeholder)
            } else if let image = beat.producer?.profilePicture {
                cell.imgProducer.kf.setImage(with: image, placeholder: placeholder)
            } else {
                cell.imgProducer.image = placeholder
            }
        } else {
            cell.lblBeatName.text = "███"
            cell.lblProducerName.text = "█████"
            cell.lblGenreName.text = "██"
            cell.imgProducer.image = placeholder
        }
        
        getSelected().loadDataIfNeeded(for: indexPath, on: tableViewBeats)

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let beat = getSelected().item(at: indexPath) {
            guard let viewController = storyboard?.instantiateViewController(withIdentifier: "MediaPreviewViewController") as? MediaPreviewViewController else {
                fatalError("couldn't instantiate MediaPreviewViewController")
            }

            viewController.media = beat
            viewController.delegate = self

            let navigationController = UINavigationController(rootViewController: viewController)
            navigationController.modalPresentationStyle = .overFullScreen

            present(navigationController, animated: true, completion: nil)
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach({ getSelected().loadDataIfNeeded(for: $0, on: tableView) })
    }
}

extension MyBeatsViewController: MediaPreviewViewControllerDelegate {

    func didAddVocalsToBeat(viewController: MediaPreviewViewController, media: Media) {
        viewController.dismiss(animated: true, completion: {
            guard let beat = media as? Beat else {
                return
            }
            self.delegate?.didSelectAddVocalsToBeat(viewController: self, beat: beat)
        })
    }

    func didLikeMedia() {
        favoriteBeats.load(tableView: tableViewBeats)
    }
}

extension MyBeatsViewController: MediaDownloaderViewControllerDelegate {

    func didDownloadMedia(viewController: MediaDownloaderViewController, media: Media, url: URL) {
        downloadedBeats.load(tableView: tableViewBeats)
        viewController.close {
            self.openBeatOptions(for: media)
        }
    }
}

extension MyBeatsViewController: MediaOptionsViewControllerDelegate {
    func didSelectAddVocalsToMedia(viewController: MediaOptionsViewController, media: Media) {
        guard let beat = media as? Beat else {
            return
        }
        self.delegate?.didSelectAddVocalsToBeat(viewController: self, beat: beat)
    }
}

extension MyBeatsViewController: TrimAudioViewControllerDelegate {
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

extension MyBeatsViewController: CaptureVideoViewControllerDelegate {
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

extension MyBeatsViewController: VideoFiltersViewControllerDelegate {
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

extension MyBeatsViewController: SaveMediaViewControllerDelegate {
    func didConfirm(viewController: SaveMediaViewController, media: Media) {
        viewController.dismiss(animated: true) {
            guard let video = media as? Video else {
                return
            }
            // TODO: implement 2017-11-28 (go to creations tab)
            // TODO: implement 2017-11-28 (upload in background)
            VideosClient.shared.upload(video: video, success: { (_) in
                // no-op
            }, failure: { error in
                self.presentErrorDialog(error: error)
            })
        }
    }

    func didCancel(viewController: SaveMediaViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
}
