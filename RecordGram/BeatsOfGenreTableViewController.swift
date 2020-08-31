//
//  BeatsOfGenreTableViewController.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/7/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import PagedArray

class BeatsOfGenreTableViewController: UITableViewController, UITableViewDataSourcePrefetching, ErrorHandler {
    @IBOutlet weak var tableBeats: UITableView! {
        didSet {
            tableBeats.prefetchDataSource = self
        }
    }

    var genre: Genre!
    
    private lazy var placeholder = UIImage(named: "media_placeholder")
    private lazy var beatsMediaComponent = BeatsMediaComponent()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = self.genre.name
        self.tabBarController?.tabBar.isTranslucent = true
        self.tabBarController?.tabBar.isHidden = true

        self.navigationController?.navigationBar.topItem?.title = ""
        let backButtonImage = UIImage(named: "backArrow")
        self.navigationController?.navigationBar.backIndicatorImage = backButtonImage
        self.navigationController?.navigationBar.backIndicatorTransitionMaskImage = backButtonImage
        
        beatsMediaComponent.load(genre: genre, tableView: tableBeats)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tabBarController?.tabBar.isHidden = false
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 95
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return beatsMediaComponent.array.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BeatsOfGenreCell", for: indexPath) as! BeatsOfGenreCell
        
        cell.countLabel.text = "\(indexPath.row + 1)"
        
        if let beat = beatsMediaComponent.array[indexPath.row] {
            cell.setup(with: beat)
        } else {
            cell.clear()
        }
        
        beatsMediaComponent.loadDataIfNeeded(genre: genre, for: indexPath, on: tableView)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach({ beatsMediaComponent.loadDataIfNeeded(genre: genre, for: $0, on: tableView) })
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let beat = beatsMediaComponent.array[indexPath.row] {
            let storyboard = UIStoryboard(name: "ARUser", bundle: Bundle.main)
            guard let viewController = storyboard.instantiateViewController(withIdentifier: "MediaPreviewViewController") as? MediaPreviewViewController else {
                fatalError("couldn't instantiate MediaPreviewViewController")
            }
            
            viewController.media = beat
            viewController.delegate = self
            
            let navigationController = UINavigationController(rootViewController: viewController)
            navigationController.modalPresentationStyle = .overFullScreen
            
            self.present(navigationController, animated: true, completion: nil)
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension BeatsOfGenreTableViewController: MediaPreviewViewControllerDelegate {
    func didAddVocalsToBeat(viewController: MediaPreviewViewController, media: Media) {
        viewController.dismiss(animated: true, completion: {
            // TODO: 2018-01-02 refactor find better way
            guard let navigationController = self.tabBarController?.viewControllers?[2] as? UINavigationController else {
                return
            }
            guard let studioViewController = navigationController.viewControllers.first as? StudioViewController else {
                return
            }
            navigationController.popToRootViewController(animated: false)
            self.tabBarController?.selectedIndex = 2
            DispatchQueue.main.async {
                studioViewController.media = media
            }
        })
    }
}

extension BeatsOfGenreTableViewController: TrimAudioViewControllerDelegate {
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

extension BeatsOfGenreTableViewController: MediaDownloaderViewControllerDelegate {

    func didDownloadMedia(viewController: MediaDownloaderViewController, media: Media, url: URL) {
        // Refresh Table View Cell
        if let index = beatsMediaComponent.array.index(where: { $0?.uuid == media.uuid }) {
            let indexPath = IndexPath(item: index, section: 0)
            
            tableBeats.reloadRows(at: [indexPath], with: .automatic)
        }
        viewController.close {
            self.openBeatOptions(for: media)
        }
    }
}

extension BeatsOfGenreTableViewController: CaptureVideoViewControllerDelegate {
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

extension BeatsOfGenreTableViewController: MediaOptionsViewControllerDelegate {
    func didSelectAddVocalsToMedia(viewController: MediaOptionsViewController, media: Media) {
            // TODO: 2018-01-02 refactor find better way
        guard let navigationController = self.tabBarController?.viewControllers?[2] as? UINavigationController else {
            return
        }
        guard let studioViewController = navigationController.viewControllers.first as? StudioViewController else {
            return
        }
        navigationController.popToRootViewController(animated: false)
        self.tabBarController?.selectedIndex = 2
        DispatchQueue.main.async {
            studioViewController.media = media
        }
    }
}

extension BeatsOfGenreTableViewController: VideoFiltersViewControllerDelegate {
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

extension BeatsOfGenreTableViewController: SaveMediaViewControllerDelegate {
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
