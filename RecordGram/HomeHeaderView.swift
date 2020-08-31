//
//  HomeHeaderView.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/6/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import IOStickyHeader

class HomeHeaderView: UICollectionReusableView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {

    @IBOutlet weak var slideshow: UICollectionView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet var buttons: [UIButton]!

    var slideshowInterval: Double = 10
    var slideshowTimer: Timer?
    var homeFeedCollectionView: UICollectionView!
    var slideNib = UINib(nibName: "SlideView", bundle: Bundle.main)
    var banners: [Any] = []

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
        slideshow.register(slideNib, forCellWithReuseIdentifier: "Slide")

        BannersClient.shared.featured(success: { banners in
            if let banners = banners {
                self.banners = banners
                self.slideshow.reloadData()
                self.setTimerIfNeeded()
            }
        }, failure: { error in })
    }

    func setTimerIfNeeded() {
        if slideshowInterval > 0 && banners.count > 1 && slideshowTimer == nil {
            slideshowTimer = Timer.scheduledTimer(timeInterval: slideshowInterval, target: self, selector: #selector(HomeHeaderView.slideshowTick(_:)), userInfo: nil, repeats: true)
        }
    }

    func getCurrentPage() -> Int {
        return slideshow.frame.size.width > 0 ? Int(slideshow.contentOffset.x / slideshow.frame.size.width) : 0
    }

    @objc func slideshowTick(_ timer: Timer) {
        let page = getCurrentPage()
        var nextPage = page + 1

        if page == banners.count - 1 {
            nextPage = 0
        }

        pageControl.currentPage = nextPage

        slideshow.scrollToItem(at: IndexPath(item: nextPage, section: 0), at: .left, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        pageControl.numberOfPages = banners.count
        return banners.count
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.frame.size
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Slide", for: indexPath) as! HomeSlideCollectionViewCell

        cell.setup(banners[indexPath.item])

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let homeViewController = parentViewController as? HomeViewController {
            if let contest = banners[indexPath.item] as? Contest {
                let storyBoard = UIStoryboard(name: "Contests", bundle: nil)
                let contestDetailsViewController = storyBoard.instantiateViewController(withIdentifier: "ContestDetailsViewController") as! ContestDetailsViewController
                contestDetailsViewController.contest = contest
                homeViewController.navigationController?.pushViewController(contestDetailsViewController, animated: true)
            } else if let media = banners[indexPath.item] as? Video {
                homeViewController.play(media)
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? HomeSlideCollectionViewCell, let video = banners[indexPath.row] as? Video else {
            return
        }
        cell.startVideo(video: video)
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? HomeSlideCollectionViewCell else {
            return
        }
        cell.stopVideo()
    }

    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if slideshowTimer?.isValid != nil {
            slideshowTimer?.invalidate()
            slideshowTimer = nil
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        pageControl.currentPage = getCurrentPage()

        setTimerIfNeeded()
    }

    @IBAction func didTapButton(_ sender: UIButton) {
        buttons.forEach { btn in
            btn.isSelected = btn == sender
        }
        homeFeedCollectionView.reloadData()
    }
}
