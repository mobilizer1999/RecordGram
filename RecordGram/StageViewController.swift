//
//  StageViewController.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/5/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import PagedArray

class StageViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDataSourcePrefetching, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var stageVideosCollectionView: UICollectionView!
    @IBOutlet weak var makeSongVideoBtn: RoundButton!
    @IBOutlet weak var profileNavButton: RoundButton!
    @IBOutlet var buttons: [UIButton]!

    var menuVC: MenuViewController!
    var menuView: UIView!

    var videos = StageMediaComponent("videos")
    var songs = StageMediaComponent("songs")

    let mediaPlaceholder = UIImage(named: "media_placeholder")

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.topItem?.title = NSLocalizedString("THE STAGE", comment: "Stage")
        self.setupAppereance()
        insertMenu()
        
        stageVideosCollectionView.prefetchDataSource = self

        videos.load(collectionView: stageVideosCollectionView)
        songs.load(collectionView: stageVideosCollectionView)
    }

    func insertMenu() {
        if let window = UIApplication.shared.keyWindow {
            let storyboard = UIStoryboard(name: "Menu", bundle: nil)
            menuVC = storyboard.instantiateViewController(withIdentifier: "menu") as! MenuViewController
            menuVC.stageVC = self
            menuView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
            menuView.isUserInteractionEnabled = false
            menuView.addSubview(menuVC.view)
            window.addSubview(menuView)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        load(profileNavButton)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    fileprivate func setupAppereance() {

        let backgroundView = UIView()
        backgroundView.backgroundColor = stageVideosCollectionView.backgroundColor
        stageVideosCollectionView.backgroundView = backgroundView

        makeSongVideoBtn.backgroundColor = UIColor.rgb(red: 186, green: 36, blue: 99, alpha: 1)
        let attributedString = NSMutableAttributedString(attributedString: NSAttributedString(string: NSLocalizedString("MAKE YOUR SONGS & VIDEOS PUBLIC AND \n GET ON THE STAGE NOW", comment: "Stage"), attributes: [NSAttributedStringKey.font: UIFont.init(name: "BebasNeueRG-Regular", size: 20) ?? ""]))
        makeSongVideoBtn.titleLabel?.numberOfLines = 0
        makeSongVideoBtn.titleLabel?.textAlignment = .center
        makeSongVideoBtn.setAttributedTitle(attributedString, for: .normal)
    }

    @IBAction func didSelectMakeMediaButton(_ sender: Any) {
        self.parent?.tabBarController?.selectedIndex = 3
    }

    @IBAction func onMenuButton(_ sender: Any) {
        menuVC.openMenu()
        menuView.isUserInteractionEnabled = true;
    }

    @IBAction func didTapButton(_ sender: UIButton) {
        buttons.forEach { btn in
            btn.isSelected = btn == sender
        }
        stageVideosCollectionView.setContentOffset(CGPoint.zero, animated: false)
        stageVideosCollectionView.reloadData()
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if buttons[0].isSelected {
            return videos.array.count
        } else {
            return songs.array.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if buttons[0].isSelected == true { // videos
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoCell", for: indexPath) as? VideoCollectionViewCell else {
                fatalError()
            }
            var media = videos.array[indexPath.item]

            cell.imgPreview.image = #imageLiteral(resourceName:"media_placeholder")

            if let video = media?.asVideo {
                cell.loadImg(for: video)
            }

            videos.loadDataIfNeeded(for: indexPath, on: collectionView)

            return cell
        }

        if buttons[1].isSelected == true { // songs
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SongCell", for: indexPath) as? SongCollectionViewCell else {
                fatalError()
            }

            if let song = songs.array[indexPath.item]?.asSong {
                cell.setup(with: song)
            } else {
                cell.clear()
                songs.loadDataIfNeeded(for: indexPath, on: collectionView)
            }

            return cell
        }

        fatalError()
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if buttons[0].isSelected == true { // videos
            let width: CGFloat = (view.frame.width / 3.0).rounded(.down)
            let height: CGFloat = (width * 16) / 9
            return CGSize(width: width, height: height)
        } else { // songs
            return CGSize(width: view.frame.width, height: 85)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if buttons[0].isSelected {
            if let video = videos.array[indexPath.item]?.asMedia {
                let storyboard = UIStoryboard(name: "Players", bundle: Bundle.main)
                guard let viewController = storyboard.instantiateViewController(withIdentifier: "MediaPlayerViewController") as? MediaPlayerViewController else {
                    fatalError("couldn't instantiate MediaPlayerViewController")
                }

                viewController.media = video

                viewController.delegate = self

                let navigationController = UINavigationController(rootViewController: viewController)

                self.present(navigationController, animated: true, completion: nil)
            }
        } else {
            if let song = songs.array[indexPath.item]?.asSong {
                play(song)
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    // MARK: - UICollectionViewDataSourcePrefetching
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        if buttons[0].isSelected == true { // videos
            indexPaths.forEach({ videos.loadDataIfNeeded(for: $0, on: collectionView) })
        } else if buttons[1].isSelected == true { // songs
            indexPaths.forEach({ songs.loadDataIfNeeded(for: $0, on: collectionView) })
        }
    }
}

extension StageViewController: MediaPlayerViewControllerDelegate {
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
