//
//  ProducersBeatsViewController.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/8/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import PagedArray

class ProducerBeatsViewController: UIViewController, ErrorHandler {

    @IBOutlet weak var shadowView: UIView!
    @IBOutlet weak var tableBeats: UITableView! {
        didSet {
            tableBeats.prefetchDataSource = self
        }
    }
    @IBOutlet weak var profileImage: RoundImageView!
    @IBOutlet weak var producerDescription: UITextView!
    @IBOutlet weak var button: UIButton!

    let placeholder = UIImage(named: "profile_placeholder")

    var uuid: String!

    private lazy var producerBeatsMediaComponent = ProducerBeatsMediaComponent(uuid: uuid)

    override func loadView() {
        super.loadView()
        
        title = ""
        profileImage.image = placeholder
        producerDescription.text = ""
        
        UserClient.shared.get(uuid: uuid, success: { user in
            self.title = user["producer_data"]["name"].stringValue
            self.profileImage.kf.setImage(with: URL(string: user["profile_picture"].stringValue), placeholder: self.placeholder)
            self.producerDescription.text = user["producer_data"]["description"].stringValue
            if user["am_following"].boolValue {
                self.button.setTitle(NSLocalizedString("UNFOLLOW", comment: "User action"), for: .normal)
            }
        }, failure: { error in
            self.presentErrorDialog(error: error)
        })
        
        producerBeatsMediaComponent.load(tableView: tableBeats)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.topItem?.title = ""
        
        let backButtonImage = UIImage(named: "backArrow")
        self.navigationController?.navigationBar.backIndicatorImage = backButtonImage
        self.navigationController?.navigationBar.backIndicatorTransitionMaskImage = backButtonImage
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.tabBarController?.tabBar.isHidden = true
        self.tabBarController?.tabBar.isTranslucent = true

        shadowView.layer.cornerRadius = shadowView.frame.size.width / 2
        shadowView.layer.shadowColor = UIColor.black.withAlphaComponent(0.3).cgColor
        shadowView.layer.shadowOffset = CGSize(width: 3.0, height: 3.0)
        shadowView.layer.shadowOpacity = 0.5
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.tabBarController?.tabBar.isHidden = false
        self.tabBarController?.tabBar.isTranslucent = false
    }

    @IBAction func onButtonTap(_ sender: Any) {
        if let isFollowing = UserClient.shared.get("am_following", for: uuid) {
            if isFollowing == "1" {
                UserClient.shared.unFollow(uuid: uuid, success: updateButton, failure: { error in })
            } else {
                UserClient.shared.follow(uuid: uuid, success: updateButton, failure: { error in })
            }
        }
    }

    func updateButton() {
        UserClient.shared.get("am_following", for: uuid) { isFollowing in
            if isFollowing == "1" {
                self.button.setTitle(NSLocalizedString("UNFOLLOW", comment: "User action"), for: .normal)
            } else {
                self.button.setTitle(NSLocalizedString("FOLLOW", comment: "User action"), for: .normal)
            }
        }
    }
}

extension ProducerBeatsViewController: UITableViewDelegate, UITableViewDataSource, UITableViewDataSourcePrefetching {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return producerBeatsMediaComponent.array.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "producerBeatCell", for: indexPath) as! ProducerBeatsTableViewCell

        cell.indexLabel.text = String(indexPath.item + 1)
        cell.beatDurationLabel.text = ""

        if let beat = producerBeatsMediaComponent.array[indexPath.item] {
            cell.setup(with: beat)
        } else {
            cell.clear()
        }
        
        producerBeatsMediaComponent.loadDataIfNeeded(for: indexPath, on: tableView)

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let beat = producerBeatsMediaComponent.array[indexPath.item] {
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
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach({ producerBeatsMediaComponent.loadDataIfNeeded(for: $0, on: tableView) })
    }
}

extension ProducerBeatsViewController: MediaPreviewViewControllerDelegate {

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

extension ProducerBeatsViewController: MediaDownloaderViewControllerDelegate {

    func didDownloadMedia(viewController: MediaDownloaderViewController, media: Media, url: URL) {
        // Refresh Table View Cell
        if let index = producerBeatsMediaComponent.array.index(where: { $0?.uuid == media.uuid }) {
            let indexPath = IndexPath(item: index, section: 0)

            tableBeats.reloadRows(at: [indexPath], with: .automatic)
        }
        viewController.close {
            self.openBeatOptions(for: media)
        }
    }
}

extension ProducerBeatsViewController: MediaOptionsViewControllerDelegate {
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

extension ProducerBeatsViewController: TrimAudioViewControllerDelegate {
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

extension ProducerBeatsViewController: CaptureVideoViewControllerDelegate {
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

extension ProducerBeatsViewController: VideoFiltersViewControllerDelegate {
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

extension ProducerBeatsViewController: SaveMediaViewControllerDelegate {
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
