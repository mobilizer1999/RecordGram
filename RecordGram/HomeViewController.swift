//
//  HomeViewController.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/5/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import AccountKit
import Kingfisher
import ImageSlideshow
import PagedArray
import IOStickyHeader

class HomeViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDataSourcePrefetching, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, ErrorHandler {
    
    fileprivate var accountKit = AKFAccountKit(responseType: .accessToken)

    @IBOutlet weak var homeFeedCollectionView: UICollectionView!
    @IBOutlet weak var profileNavButton: RoundButton!
    @IBOutlet weak var collectionView: UICollectionView!

    var header: HomeHeaderView?
    let headerNib = UINib(nibName: "HomeHeaderView", bundle: Bundle.main)

    var songs = HomeMediaComponent("songs")
    var videos = HomeMediaComponent("videos")

    var menuVC: MenuViewController!
    var menuView: UIView!

    let mediaPlaceholder = UIImage(named: "media_placeholder")

    override func loadView() {
        super.loadView()

        let backgroundView = UIView()
        backgroundView.backgroundColor = collectionView.backgroundColor
        collectionView.backgroundView = backgroundView
        
        collectionView.prefetchDataSource = self

        songs.load(collectionView: nil)
        videos.load(collectionView: homeFeedCollectionView)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        insertMenu()
        
        setupStickyHeader()
    }
    
    func insertMenu() {
        if let window = UIApplication.shared.keyWindow {
            let storyboard = UIStoryboard(name: "Menu", bundle: nil)
            menuVC = storyboard.instantiateViewController(withIdentifier: "menu") as! MenuViewController
            menuVC.homeVC = self
            menuView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
            menuView.isUserInteractionEnabled = false
            menuView.addSubview(menuVC.view)
            window.addSubview(menuView)
        }
    }
    
    func setupStickyHeader() {
        
        if let layout = homeFeedCollectionView.collectionViewLayout as? IOStickyHeaderFlowLayout {
            layout.parallaxHeaderReferenceSize = CGSize(width: view.frame.width, height: view.frame.width / 16 * 9 + 75)
            layout.parallaxHeaderMinimumReferenceSize = CGSize(width: view.frame.width, height: 55)
            layout.parallaxHeaderAlwaysOnTop = true
            layout.disableStickyHeaders = true
        }
        
        self.collectionView.register(self.headerNib, forSupplementaryViewOfKind: IOStickyHeaderParallaxHeader, withReuseIdentifier: "HomeHeaderView")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        load(profileNavButton)
        self.navigationController?.navigationBar.topItem?.title = NSLocalizedString("HOME", comment: "Home")

        let appDelegate = UIApplication.shared.delegate as! AppDelegate

        let shouldGetCurrentLocation = !(appDelegate.mainTab?.shouldShowTour ?? false)

        if shouldGetCurrentLocation {
            LocationTracker.shared.getCurrentLocation(completionHandler: nil)
        }
    }

    @IBAction func onMenuButton(_ sender: Any) {
        menuVC.openMenu()
        menuView.isUserInteractionEnabled = true;
    }

    var selectedMedia: HomeMediaComponent? {
        if let header = header {
            if header.buttons[0].isSelected {
                return videos
            }
            if header.buttons[1].isSelected {
                return songs
            }
        }
        return nil
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "HomeHeaderView", for: indexPath) as? HomeHeaderView

        if let header = header {
            header.homeFeedCollectionView = homeFeedCollectionView
        }

        return header!
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let media = selectedMedia {
            return media.array.count
        }
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if header?.buttons[0].isSelected == true { // videos
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoCell", for: indexPath) as? VideoCollectionViewCell else {
                fatalError()
            }
            var media = selectedMedia?.array[indexPath.item]

            cell.imgPreview.image = mediaPlaceholder

            if let video = media?.asVideo {
                cell.loadImg(for: video)
            }
            
            selectedMedia?.loadDataIfNeeded(for: indexPath, on: collectionView)

            return cell
        }

        if header?.buttons[1].isSelected == true { // songs
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SongCell", for: indexPath) as? SongCollectionViewCell else {
                fatalError()
            }

            if let song = selectedMedia?.array[indexPath.item]?.asSong {
                cell.setup(with: song)
            } else {
                cell.clear()
                selectedMedia?.loadDataIfNeeded(for: indexPath, on: collectionView)
            }

            return cell
        }

        fatalError()
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if header?.buttons[0].isSelected == true { // videos
            let width: CGFloat = (view.frame.width / 3.0).rounded(.down)
            let height: CGFloat = (width * 16) / 9
            return CGSize(width: width, height: height)
        } else { // songs
            return CGSize(width: view.frame.width, height: 85)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let video = selectedMedia?.array[indexPath.item]?.asVideo {
            play(video)
        } else if let song = selectedMedia?.array[indexPath.item]?.asSong {
            play(song)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func play(_ media: Video?) {
        let storyboard = UIStoryboard(name: "Players", bundle: Bundle.main)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "MediaPlayerViewController") as? MediaPlayerViewController else {
            fatalError("couldn't instantiate MediaPlayerViewController")
        }


        viewController.media = media

        viewController.delegate = self

        let navigationController = UINavigationController(rootViewController: viewController)

        self.present(navigationController, animated: true, completion: nil)
    }
    
    // MARK: - UICollectionViewDataSourcePrefetching
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        if header?.buttons[0].isSelected == true { // videos
            indexPaths.forEach({ videos.loadDataIfNeeded(for: $0, on: collectionView) })
        } else if header?.buttons[1].isSelected == true { // songs
            indexPaths.forEach({ songs.loadDataIfNeeded(for: $0, on: collectionView) })
        }
    }
}


extension HomeViewController: MediaPlayerViewControllerDelegate {
    func didDismiss(viewController: MediaPlayerViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }

    func didDeleteMedia(viewController: MediaPlayerViewController, media: Media) {
        viewController.dismiss(animated: true, completion: {
            // TODO: implement 2017-11-30 ()
        })
    }

    func didLikeMedia(viewController: MediaPlayerViewController, media: Media) {
        // TODO: implement 2017-11-30 (?)
    }

    func didCommentMedia(viewController: MediaPlayerViewController, media: Media) {
        viewController.dismiss(animated: true, completion: {
            // TODO: implement 2017-11-30 ()
        })
    }

    func didUpdateMediaInfo(viewController: MediaPlayerViewController, media: Media) {
        viewController.dismiss(animated: true, completion: {

        })
    }
}
