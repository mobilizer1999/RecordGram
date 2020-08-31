//
//  ProfileViewController.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/6/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import AccountKit
import FBSDKLoginKit
import SwiftyJSON

class ProfileViewController: UIViewController, UpdateBioProtocol, ErrorHandler {

    @IBOutlet var btnTabs: [UIButton]!
    @IBOutlet weak var followingBtn: UIButton!
    @IBOutlet weak var fansBtn: UIButton!
    @IBOutlet weak var followUnfollowBtn: UIButton!
    @IBOutlet weak var myMediaCollectionView: UICollectionView!
    @IBOutlet weak var mediaOptionsView: UIView!
    @IBOutlet weak var userBioTextView: UITextView!
    @IBOutlet weak var profileImageView: ProfileUIImageView!
    @IBOutlet weak var messageButton: UIButton!
    @IBOutlet weak var isVerified: UIImageView!

    let userDefaults = UserDefaults.standard

    lazy var myProfile = uuid == UserClient.shared.uuid()
    var uuid: String!


    var songs = ProfileMediaComponent()
    var videos = ProfileMediaComponent()

    let placeholder = #imageLiteral(resourceName:"media_placeholder")

    var selectedMedia: Media?

    override func loadView() {
        super.loadView()
        followUnfollowBtn.layer.cornerRadius = followUnfollowBtn.bounds.height / 2
        if myProfile {
            followUnfollowBtn.setTitle(NSLocalizedString("My Beats", comment: "My beats"), for: .normal)
            messageButton.isHidden = true

            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ARProfileViewController.presentBioVC))
            userBioTextView.addGestureRecognizer(tapGesture)
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "Settings icon"), style: .plain, target: self, action: #selector(ProfileViewController.onSettingsButton))

        songs.loadSong(uuid: uuid, collectionView: myMediaCollectionView)
        videos.loadVideo(uuid: uuid, collectionView: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        mediaOptionsView.isHidden = true
        mediaOptionsView.alpha = 0.0
    }

    @objc func presentBioVC() {
        let storyboard = UIStoryboard.init(name: "Settings", bundle: nil)
        let bioVC = storyboard.instantiateViewController(withIdentifier: "UpdateBioViewController") as! UpdateBioViewController
        self.present(bioVC, animated: true, completion: nil)
    }

    func userUpdated(string: String) {
        userBioTextView.text = string
    }

    fileprivate func showMediaOptionsView() {
        UIView.animate(withDuration: 0.3) {
            self.mediaOptionsView.alpha = 1.0
        }
        mediaOptionsView.isHidden = false
    }

    fileprivate func hideMediaOptionsView() {
        UIView.animate(withDuration: 0.3) {
            self.mediaOptionsView.alpha = 0.0
        }
        mediaOptionsView.isHidden = true
    }

    @objc fileprivate func onSettingsButton() {
        if myProfile {
            let storyBoard: UIStoryboard = UIStoryboard(name: "Settings", bundle: nil)
            let profileVC = storyBoard.instantiateViewController(withIdentifier: "SettingsTableViewController") as! SettingsTableViewController
            self.navigationController?.pushViewController(profileVC, animated: true)
        } else {
            otherUserSettings(with: uuid)
        }
    }

    @IBAction func onBackButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.navigationBar.isHidden = false
        self.navigationController?.navigationBar.isTranslucent = false
        self.tabBarController?.tabBar.isTranslucent = true
        self.tabBarController?.tabBar.isHidden = true

        self.profileImageView.fetch(for: self.uuid) {
            UserClient.shared.get("username", for: self.uuid) { username in
                self.title = "@" + username
            }
            UserClient.shared.get("bio", for: self.uuid) { bio in
                self.userBioTextView.text = bio.decodeEmoji
            }
            UserClient.shared.get("following_count", for: self.uuid) { following in
                self.followingBtn.setTitle(following, for: .normal)
            }
            UserClient.shared.get("follower_count", for: self.uuid) { fans in
                self.fansBtn.setTitle(fans, for: .normal)
            }
            UserClient.shared.get("follows_me", for: self.uuid) { followsMe in
                self.messageButton.isHidden = followsMe == "0"
            }
            UserClient.shared.get("is_verified", for: self.uuid) { isVerified in
                self.isVerified.isHidden = isVerified == "0"
            }
            if !self.myProfile {
                UserClient.shared.get("am_following", for: self.uuid) { isFollowing in
                    if isFollowing == "1" {
                        self.followUnfollowBtn.setTitle(NSLocalizedString("UNFOLLOW", comment: "User action"), for: .normal)
                    }
                }
            }
        }
        super.viewWillAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }

    // MARK - Segment Control Button Actions
    @IBAction func didTapMySongsButton(_ sender: UIButton) {
        btnTabs.forEach { (btn) in
            btn.isSelected = btn == sender
        }
        myMediaCollectionView.reloadData()
    }

    @IBAction func didTapMyVideosButton(_ sender: UIButton) {
        btnTabs.forEach { (btn) in
            btn.isSelected = btn == sender
        }
        myMediaCollectionView.reloadData()
    }

    // MARK: - Media Option Actions
    @IBAction func onCloseMediaOptionsView(_ sender: Any) {
        hideMediaOptionsView()
    }

    func getData() -> ProfileMediaComponent? {
        if btnTabs[0].isSelected {
            return songs
        }
        if btnTabs[1].isSelected {
            return videos
        }
        return nil
    }

    @IBAction func onButton(_ sender: UIButton) {
        if myProfile {
            let storyboard = UIStoryboard(name: "ARUser", bundle: Bundle.main)
            guard let viewController = storyboard.instantiateViewController(withIdentifier: "MyBeatsViewController") as? MyBeatsViewController else {
                return
            }

            viewController.delegate = self
            viewController.hideTabs = true

            navigationController?.pushViewController(viewController, animated: true)
        } else if let isFollowing = UserClient.shared.get("am_following", for: uuid) {
            if isFollowing == "1" {
                UserClient.shared.unFollow(uuid: uuid, success: updateFans, failure: { error in })
            } else {
                UserClient.shared.follow(uuid: uuid, success: updateFans, failure: { error in })
            }
        }
    }

    func updateFans() {
        UserClient.shared.get("follower_count", for: uuid) { fans in
            self.fansBtn.setTitle(fans, for: .normal)
            UserClient.shared.get("am_following", for: self.uuid) { isFollowing in
                if isFollowing == "1" {
                    self.followUnfollowBtn.setTitle(NSLocalizedString("UNFOLLOW", comment: "User action"), for: .normal)
                } else {
                    self.followUnfollowBtn.setTitle(NSLocalizedString("FOLLOW", comment: "User action"), for: .normal)
                }
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? FollowingTableViewController {
            vc.uuid = uuid
        } else if let vc = segue.destination as? FansTableViewController {
            vc.uuid = uuid
        }
    }

    @IBAction func onMessageButton(_ sender: Any) {
        UserClient.shared.get(uuid: uuid, success: { user in
            let chatVC = UIStoryboard(name: "Messages", bundle: nil).instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
            chatVC.recipient = UserClient.user(fromJson: user)
            self.navigationController?.pushViewController(chatVC, animated: true)
        }, failure: { error in })
    }

    @IBAction func playSong(_ sender: Any) {
        hideMediaOptionsView()
        if let song = selectedMedia {
            playMedia(song)
        }
    }

    @IBAction func shareSong(_ sender: Any) {
        hideMediaOptionsView()
        if let song = selectedMedia as? Song {
            guard let uuid = song.uuid else {
                return
            }
            
            let url = "http://view.cre8tor.app/\(uuid)"
            let username = song.user?.name ?? NSLocalizedString("Unknown", comment: "Unknown username")
            let message = String(format: NSLocalizedString("Check this out. It was made on @Cre8tor by %@.", comment: "Share"), username)
            let items: [Any] = [message, url]
            
            let activityController = UIActivityViewController(activityItems: items, applicationActivities: nil)
            activityController.popoverPresentationController?.sourceView = self.view
            activityController.popoverPresentationController?.sourceRect = self.view.frame

            self.present(activityController, animated: true, completion: nil)
        }
    }

    func playMedia(_ media: Media) {
        let storyboard = UIStoryboard(name: "Players", bundle: Bundle.main)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "MediaPlayerViewController") as? MediaPlayerViewController else {
            fatalError("couldn't instantiate MediaPlayerViewController")
        }

        viewController.media = media
        viewController.delegate = self

        let navigationController = UINavigationController(rootViewController: viewController)

        self.present(navigationController, animated: true, completion: nil)
    }
}

extension ProfileViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if btnTabs[0].isSelected {
            return songs.array.count
        } else {
            return videos.array.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if btnTabs[0].isSelected {
            return CGSize(width: view.frame.width, height: 85)
        } else {
            let width: CGFloat = (view.frame.width / 3.0).rounded(.down)
            let height: CGFloat = (width * 16) / 9
            return CGSize(width: width, height: height)
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if btnTabs[0].isSelected {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SongCell", for: indexPath) as! SongCollectionViewCell
            let song = songs.array[indexPath.row]
            if let song = song as? Song {
                cell.setup(with: song)
            } else {
                cell.clear()
                songs.loadSongDataIfNeeded(uuid: uuid, for: indexPath, collectionView: collectionView)
            }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyVideoCell", for: indexPath) as! VideoCollectionViewCell
            cell.imgPreview.image = placeholder
            let video = videos.array[indexPath.row]
            if let video = video as? Video {
                cell.loadImg(for: video)
            } else {
                videos.loadVideoDataIfNeeded(uuid: uuid, for: indexPath, collectionView: collectionView)
            }
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if btnTabs[0].isSelected {
            if let song = songs.array[indexPath.row] as? Song {
                play(song)
            }
        } else {
            if let video = videos.array[indexPath.row] {
                playMedia(video)
            }
        }
    }
}

extension ProfileViewController: AddVocalsToBeatDelegate {
    func didSelectAddVocalsToBeat(viewController: MyBeatsViewController, beat: Beat) {
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
            studioViewController.media = beat
        }
    }

    func didCancel(viewController: MyBeatsViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
}

extension ProfileViewController: MediaPlayerViewControllerDelegate {
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
