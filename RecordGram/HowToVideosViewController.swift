//
//  HowToVideosViewController.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 10/11/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.

import UIKit
import PagedArray
import CoreMedia

class HowToVideosViewController: UIViewController, ErrorHandler {

    @IBOutlet weak var tableView: UITableView!

    let placeholder = UIImage(named: "media_placeholder")

    var array: [HowToVideo] = []

    private var mediaPlayer: MediaPlayer?
    private var close: UIButton?

    override func loadView() {
        super.loadView()
        title = NSLocalizedString("How To Videos", comment: "How to Videos")
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName:"backArrow"), style: .plain, target: self, action: #selector(HowToVideosViewController.onBackButton))
        VideosClient.shared.howTo(success: { videos in
            if let videos = videos {
                self.array = videos
                self.tableView.reloadData()
            }
        }, failure: { error in
            self.presentErrorDialog(error: error)
        })
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
        tabBarController?.tabBar.isTranslucent = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }

    @objc func onBackButton() {
        navigationController?.popViewController(animated: true)
    }

    @objc func closeVideo() {
        mediaPlayer?.playerView?.removeFromSuperview()
        mediaPlayer?.playerView = nil
        mediaPlayer?.stop()
        mediaPlayer = nil

        if let close = self.close {
            close.removeFromSuperview()
            self.close = nil
        }
    }
}

extension HowToVideosViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return array.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "howToVideosCell") as! HowToVideoTableViewCell

        let video = array[indexPath.item]
        if let title = video.title {
            cell.title.text = title
        } else {
            cell.title.text = ""
        }
        if let thumb = video.thumb {
            cell.thumb.kf.setImage(with: thumb, placeholder: placeholder)
        } else {
            cell.thumb.image = placeholder
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.mediaPlayer = MediaPlayer(url: array[indexPath.row].path!)
        self.mediaPlayer?.delegate = self

        let playerView = PlayerView()
        playerView.frame = UIScreen.main.bounds

        let window = UIApplication.shared.keyWindow!

        window.addSubview(playerView)

        close = UIButton()
        close!.setImage(UIImage(named: "ic_close"), for: .normal)

        close!.addTarget(self, action: #selector(HowToVideosViewController.closeVideo), for: .touchUpInside)

        window.addSubview(close!)

        close!.snp.makeConstraints { make in
            make.width.height.equalTo(33)
            make.top.equalToSuperview().offset(30)
            make.trailing.equalToSuperview().offset(-10)
        }

        self.mediaPlayer?.playerView = playerView
    }
}

extension HowToVideosViewController: MediaPlayerDelegate {
    func onReadyToPlay(player: MediaPlayer) {
//        if !CMTIME_IS_INDEFINITE(player.duration) {
//            sldProgress.maximumValue = Float(player.duration.seconds)
//        }
    }

    func onPeriodicTimeObserver(player: MediaPlayer, time: CMTime) {
//        sldProgress.setValue(Float(time.seconds), animated: true)
    }

    func didPlayToEndTime(player: MediaPlayer) {
        player.seek(to: 0) { (_) in
            player.play()
        }
    }

    func didStartPlaying(player: MediaPlayer) {
    }

    func onFailure(error: Error) {
        self.presentErrorDialog(error: error)
    }
}
