//
//  MusicViewController.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/5/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import ImageSlideshow
import PagedArray

class MusicViewController: UIViewController, ErrorHandler {
    
    let genreCell = "genreCell"
    let whatsHotCell = "whatsHotCell"
    
    private var banners: [(UIImage, String)]?
    
    @IBOutlet weak var collectionGenres: UICollectionView! {
        didSet {
            collectionGenres.prefetchDataSource = self
        }
    }
    @IBOutlet weak var tableBeats: UITableView! {
        didSet {
            tableBeats.prefetchDataSource = self
        }
    }
    @IBOutlet weak var lblGenres: UILabel!
    @IBOutlet weak var btnSearchByProducers: UIButton!
    @IBOutlet weak var profileNavButton: RoundButton!
    @IBOutlet weak var slideshow: ImageSlideshow!
    
    var menuVC: MenuViewController!
    var menuView: UIView!
    
    var beatsMediaComponent: BeatsMediaComponent
    var genresMediaComponent: GenresMediaComponent
    
    required init?(coder aDecoder: NSCoder) {
        beatsMediaComponent = BeatsMediaComponent()
        genresMediaComponent = GenresMediaComponent()
        
        super.init(coder: aDecoder)
    }
    
    override func loadView() {
        super.loadView()
        
        slideshow.contentScaleMode = .scaleAspectFill
        slideshow.slideshowInterval = 3
        
        BannersClient.shared.all(success: { banners in
            guard let banners = banners  else {
                return
            }
            
            self.slideshow.setImageInputs(banners.compactMap({ ImageSource(image: $0.0) }))
        }, failure: { error in })
        
        genresMediaComponent.load(collectionView: collectionGenres)
        beatsMediaComponent.load(tableView: tableBeats)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        insertMenu()
        setupNavigationBar()
    }
    
    func setupNavigationBar() {
        if profileNavButton == nil { // Means that we are in another navigation stack
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "Search Icon"), style: .plain, target: self, action: #selector(MusicViewController.onSearchButton))
            self.navigationController?.navigationBar.topItem?.title = ""
            setupNavigationBarBackButton()
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }
    
    func insertMenu() {
        if let window = UIApplication.shared.keyWindow {
            let storyboard = UIStoryboard(name: "Menu", bundle: nil)
            menuVC = storyboard.instantiateViewController(withIdentifier: "menu") as! MenuViewController
            menuVC.musicVC = self
            menuView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
            menuView.isUserInteractionEnabled = false
            menuView.addSubview(menuVC.view)
            window.addSubview(menuView)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.title = NSLocalizedString("MUSIC", comment: "Music")
        if profileNavButton != nil {
            load(profileNavButton)
        } else { //Means that we are in another navigation stack
            //self.title = "MUSIC"
        }
        
        guard let indexPath = tableBeats.indexPathForSelectedRow else {
            return
        }
        tableBeats.deselectRow(at: indexPath, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        BannersClient.shared.all(success: { banners in
            self.banners = banners
        }, failure: { error in
            self.presentErrorDialog(error: error)
        })
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(MusicViewController.didTapBanner))
        slideshow.addGestureRecognizer(gestureRecognizer)
    }
    
    // MARK: IBActions
    
    @IBAction func onMenuButton(_ sender: Any) {
        menuVC.openMenu()
        menuView.isUserInteractionEnabled = true;
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "BeatsOfGenre") {
            let vc = segue.destination as! BeatsOfGenreTableViewController
            
            vc.genre = genresMediaComponent.array[collectionGenres.indexPath(for: sender as! UICollectionViewCell)!.item]
        }
    }
    
    @objc func didTapBanner() {
        if let uuid = banners?[slideshow.currentPage].1 {
            goToProducerProfile(with: uuid)
        }
    }
}

extension MusicViewController: UICollectionViewDataSource, UICollectionViewDataSourcePrefetching, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return genresMediaComponent.array.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: genreCell, for: indexPath) as! GenreUICollectionViewCell
        let genre = genresMediaComponent.array[indexPath.row]
        
        cell.image.image = UIImage(named: genre?.name ?? "")
        
        genresMediaComponent.loadDataIfNeeded(for: indexPath, on: collectionView)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        indexPaths.forEach({ genresMediaComponent.loadDataIfNeeded(for: $0, on: collectionView) })
    }
}

extension MusicViewController: UITableViewDelegate, UITableViewDataSource, UITableViewDataSourcePrefetching {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return beatsMediaComponent.array.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: whatsHotCell, for: indexPath) as? WhatsHotTableViewCell else {
            abort()
        }
        
        if let beat = beatsMediaComponent.array[indexPath.item] {
            cell.setup(with: beat)
        } else {
            cell.clear()
        }
        
        beatsMediaComponent.loadDataIfNeeded(for: indexPath, on: tableView)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? WhatsHotTableViewCell,
            !cell.downloading,
            let beat = beatsMediaComponent.array[indexPath.item] {
            let storyboard = UIStoryboard(name: "ARUser", bundle: Bundle.main)
            guard let viewController = storyboard.instantiateViewController(withIdentifier: "MediaPreviewViewController") as? MediaPreviewViewController else {
                fatalError("couldn't instantiate MediaPreviewViewController")
            }
            
            viewController.media = beat
            viewController.delegate = self
            viewController.modalPresentationStyle = .overFullScreen
            
            self.present(viewController, animated: true)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach({ beatsMediaComponent.loadDataIfNeeded(for: $0, on: tableView) })
    }
    
    func reloadRow(for media: Media) {
        // Refresh Table View Cell
        guard let index = beatsMediaComponent.array.index(where: { $0?.uuid == media.uuid }) else {
            return
        }
        
        tableBeats.reloadRows(at: [IndexPath(item: index, section: 0)], with: .automatic)
    }
}

extension MusicViewController: MediaPreviewViewControllerDelegate {
    
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

extension MusicViewController: MediaDownloaderViewControllerDelegate {
    
    func didDownloadMedia(viewController: MediaDownloaderViewController, media: Media, url: URL) {
        reloadRow(for: media)
        viewController.close {
            self.openBeatOptions(for: media)
        }
    }
}

extension MusicViewController: MediaOptionsViewControllerDelegate {
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
        self.navigationController?.popToRootViewController(animated: false)
    }
}

extension MusicViewController: TrimAudioViewControllerDelegate {
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

extension MusicViewController: CaptureVideoViewControllerDelegate {
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

extension MusicViewController: VideoFiltersViewControllerDelegate {
    func didConfirm(viewController: VideoFiltersViewController, base: Media?, outputUrl: URL) {
        viewController.navigationController?.dismiss(animated: true) {
            let storyboard = UIStoryboard(name: "VideoCapture", bundle: Bundle.main)
            guard let viewController = storyboard.instantiateViewController(withIdentifier: "SaveMediaViewController") as? SaveMediaViewController else {
                fatalError("couldn't instantiate SaveMediaViewController")
            }
            
            viewController.url = outputUrl
            viewController.base = base
            viewController.delegate = self
            viewController.modalPresentationStyle = .overCurrentContext
            
            if let tabBarController = self.tabBarController {
                tabBarController.present(viewController, animated: true, completion: nil)
            } else {
                self.present(viewController, animated: true, completion: nil)
            }
        }
    }
    
    func didCancel(viewController: VideoFiltersViewController) {
        viewController.navigationController?.popViewController(animated: true)
    }
}

extension MusicViewController: SaveMediaViewControllerDelegate {
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
