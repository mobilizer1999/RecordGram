//
//  HomeSlideCollectionViewCell.swift
//  RecordGram
//
//  Created by Nicolas Gonzalez on 3/31/18.
//  Copyright © 2018 Meridian Inc. All rights reserved.
//

import UIKit

class HomeSlideCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var labelStack: UIStackView!
    @IBOutlet weak var contestNameLabel: UILabel!
    @IBOutlet weak var hashTagLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    private var mediaPlayer: MediaPlayer?
    private var playerView: PlayerView?

    func setup(_ item: Any) {
        if let contest = item as? Contest {
            labelStack.isHidden = false

            if let thumbnail = contest.thumbnail {
                backgroundImage.kf.setImage(with: thumbnail, placeholder: #imageLiteral(resourceName:"gradientButtonBG"))
            }

            contestNameLabel.text = contest.title
            hashTagLabel.text = "#\(contest.hashtag ?? "")"
            dateLabel.text = ContestTableViewCell.contestEndTimeFormatStr(withContest: contest)

        } else if let _ = item as? Video {
            labelStack.isHidden = true
        } else if let song = item as? Song {
            labelStack.isHidden = true

            if let thumbnail = song.user?.picture {
                backgroundImage.kf.setImage(with: thumbnail, placeholder: #imageLiteral(resourceName:"gradientButtonBG"))
            }
        } else if let staticBanner = item as? StaticBanner {
            labelStack.isHidden = true
            
            if let path = staticBanner.path {
                backgroundImage.kf.setImage(with: URL(fileURLWithPath: path))
            }
        }
    }

    func startVideo(video: Video) {
        if let url = video.url {
            let playerView = PlayerView()
            playerView.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)

            addSubview(playerView)

            let btnPlayPause = UIButton(type: .custom)
            btnPlayPause.frame = CGRect(x: 20, y: frame.height - 30 - 20, width: 30, height: 30)
            btnPlayPause.layer.cornerRadius = 15
            btnPlayPause.layer.masksToBounds = true
            btnPlayPause.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            btnPlayPause.setImage(#imageLiteral(resourceName: "videoPlay"), for: .normal)
            btnPlayPause.setImage(#imageLiteral(resourceName: "videoPause"), for: .selected)
            btnPlayPause.addTarget(self, action: #selector(didTapPlayPauseButton(_:)), for: .touchUpInside)
            btnPlayPause.isSelected = true

            playerView.addSubview(btnPlayPause)

            playerView.layoutIfNeeded()
            btnPlayPause.layoutIfNeeded()

            self.playerView = playerView

            mediaPlayer = MediaPlayer(url: url)
            mediaPlayer?.playerView = playerView
            mediaPlayer?.loop = true

            let leadingConstraint = NSLayoutConstraint(item: btnPlayPause, attribute: .leading, relatedBy: .equal, toItem: playerView, attribute: .leading, multiplier: 1, constant: 20)
            let bottomConstraint = NSLayoutConstraint(item: btnPlayPause, attribute: .bottom, relatedBy: .equal, toItem: playerView, attribute: .bottom, multiplier: 1, constant: -20)

            NSLayoutConstraint.activate([leadingConstraint, bottomConstraint])
        }
    }

    func stopVideo() {
        mediaPlayer?.stop()
        mediaPlayer = nil

        playerView?.removeFromSuperview()
        playerView = nil
    }

    @IBAction func didTapPlayPauseButton(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected

        if sender.isSelected {
            mediaPlayer?.play()
        } else {
            mediaPlayer?.pause()
        }
    }
}
