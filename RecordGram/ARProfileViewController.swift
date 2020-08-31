//
//  ARProfileViewController.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/9/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit

class ARProfileViewController: UIViewController {

    let userDefaults = UserDefaults.standard

    let placeholder = #imageLiteral(resourceName:"profile_placeholder")
    let mediaPlaceholder = #imageLiteral(resourceName:"media_placeholder")

    @IBOutlet weak var userProfileImageview: ProfileUIImageView!
    @IBOutlet weak var verifiedImageView: UIImageView!
    @IBOutlet weak var followUnfollowButtom: UIButton!
    @IBOutlet weak var messageButton: UIButton!
    @IBOutlet weak var userBioTextView: UITextView!
    @IBOutlet weak var followersButton: UIButton!
    @IBOutlet weak var myBeatsButton: UIButton!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var mediaCollectionView: UICollectionView!
    @IBOutlet weak var personalContentButton: RoundButton!
    @IBOutlet weak var buttonContainer: UIView!
    @IBOutlet weak var mediaOptionsView: UIView!

    lazy var myProfile = uuid == UserClient.shared.uuid()
    var uuid: String!

    let artists = FollowingComponent()
    let scoutVideos = ProfileMediaComponent()
    let scoutSongs = ProfileMediaComponent()

    let videos = ProfileMediaComponent()
    let songs = ProfileMediaComponent()

    var selectedMedia: Media?

    override func loadView() {
        super.loadView()
        if myProfile {
            buttonContainer.isHidden = true
            myBeatsButton.isHidden = false

            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ARProfileViewController.presentBioVC))
            userBioTextView.addGestureRecognizer(tapGesture)
        } else {
            followUnfollowButtom.imageView?.contentMode = .scaleAspectFit
            messageButton.imageView?.contentMode = .scaleAspectFit
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "Settings icon"), style: .plain, target: self, action: #selector(ARProfileViewController.onSettingsButton))

        personalContentButton.setTitleColor(.white, for: .selected)

        artists.load(uuid: uuid, view: nil)
        scoutVideos.loadScoutVideos(uuid: uuid, collectionView: mediaCollectionView)
        scoutSongs.loadScoutSongs(uuid: uuid, collectionView: nil)
        videos.loadVideo(uuid: uuid, collectionView: nil)
        songs.loadSong(uuid: uuid, collectionView: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBarBackButton()
        segmentedControl.layer.cornerRadius = 4
        segmentedControl.selectedSegmentIndex = 1
    }

    @objc func presentBioVC() {
        let storyboard = UIStoryboard.init(name: "Settings", bundle: nil)
        let bioVC = storyboard.instantiateViewController(withIdentifier: "UpdateBioViewController") as! UpdateBioViewController
        self.present(bioVC, animated: true, completion: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.navigationBar.isHidden = false
        self.navigationController?.navigationBar.isTranslucent = false
        self.tabBarController?.tabBar.isTranslucent = true
        self.tabBarController?.tabBar.isHidden = true

        self.userProfileImageview.fetch(for: self.uuid) {
            UserClient.shared.get("username", for: self.uuid) { username in
                self.title = "@" + username
            }
            UserClient.shared.get("bio", for: self.uuid) { bio in
                self.userBioTextView.text = bio.decodeEmoji
            }
            UserClient.shared.get("follower_count", for: self.uuid) { fans in
                let title = String(format: NSLocalizedString("FANS (%d)", comment: "AR Profile"), fans)

                self.followersButton.setTitle(title, for: .normal)
            }
            UserClient.shared.get("follows_me", for: self.uuid) { followsMe in
                self.messageButton.isHidden = followsMe == "0"
            }
            UserClient.shared.get("is_verified", for: self.uuid) { isVerified in
                self.verifiedImageView.isHidden = isVerified == "0"
            }
            if !self.myProfile {
                self.updateFollowUnFollowButton()
            }
        }
        super.viewWillAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }

    @objc func onSettingsButton() {
        if myProfile {
            let storyBoard: UIStoryboard = UIStoryboard(name: "Settings", bundle: nil)
            let profileVC = storyBoard.instantiateViewController(withIdentifier: "SettingsTableViewController") as! SettingsTableViewController
            self.navigationController?.pushViewController(profileVC, animated: true)
        } else {
            otherUserSettings(with: uuid)
        }
    }

    @IBAction func onFollowUnfollowButton(_ sender: Any) {
        UserClient.shared.get("am_following", for: self.uuid) { amFollowing in
            self.followUnFollow(amFollowing == "1")
        }
    }

    func followUnFollow(_ amFollowing: Bool) {
        if amFollowing {
            UserClient.shared.unFollow(uuid: self.uuid, success: self.updateFans, failure: { error in })
        } else {
            UserClient.shared.follow(uuid: self.uuid, success: self.updateFans, failure: { error in })
        }
    }

    func updateFans() {
        UserClient.shared.get("follower_count", for: uuid) { fans in
            let title = String(format: NSLocalizedString("FANS (%d)", comment: "AR Profile"), fans)

            self.followersButton.setTitle(title, for: .normal)
            self.updateFollowUnFollowButton()
        }
    }

    func updateFollowUnFollowButton() {
        UserClient.shared.get("am_following", for: self.uuid) { amFollowing in
            self.setFollowUnFollowButton(self.followUnfollowButtom, amFollowing: amFollowing == "1")
        }
    }

    @IBAction func onMessageButton(_ sender: Any) {
        UserClient.shared.get(uuid: uuid, success: { user in
            let chatVC = UIStoryboard(name: "Messages", bundle: nil).instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
            chatVC.recipient = UserClient.user(fromJson: user)
            self.navigationController?.pushViewController(chatVC, animated: true)
        }, failure: { error in })
    }

    @IBAction func onFollowersButton(_ sender: Any) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Profile", bundle: nil)
        let profileVC = storyBoard.instantiateViewController(withIdentifier: "FansTableViewController") as! FansTableViewController
        profileVC.uuid = uuid
        self.navigationController?.pushViewController(profileVC, animated: true)
    }

    @IBAction func onSegmentedController(_ sender: UISegmentedControl) {
        mediaCollectionView.reloadData()
    }

    @IBAction func onPersonalContentButton(_ sender: UIButton) {
        if sender.isSelected {
            sender.setTitle(NSLocalizedString("PERSONAL CONTENT", comment: "AR Profile"), for: .normal)
            sender.isSelected = false
            segmentedControl.insertSegment(withTitle: NSLocalizedString("ARTISTS", comment: "AR Profile"), at: 0, animated: false)
            segmentedControl.selectedSegmentIndex = 0
            segmentedControl.selectedSegmentIndex = 1
        } else {
            sender.setTitle(NSLocalizedString("SCOUT CONTENT", comment: "AR Profile"), for: .selected)
            sender.isSelected = true
            segmentedControl.removeSegment(at: 0, animated: false)
            segmentedControl.selectedSegmentIndex = 1
            segmentedControl.selectedSegmentIndex = 0
        }
        mediaCollectionView.reloadData()
    }

    fileprivate func showMediaOptionsView() {
        UIView.animate(withDuration: 0.3) {
            self.mediaOptionsView.alpha = 1.0
        }
        mediaOptionsView.isHidden = false
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
            let username = song.user?.toString() ?? NSLocalizedString("Unknown", comment: "Unknown username")
            let message = String(format: NSLocalizedString("Check this out. It was made on @Cre8tor by %@.", comment: "Share"), username)

            let items: [Any] = [message, url]
            
            let activityController = UIActivityViewController(activityItems: items, applicationActivities: nil)
            activityController.popoverPresentationController?.sourceView = self.view
            activityController.popoverPresentationController?.sourceRect = self.view.frame

            self.present(activityController, animated: true, completion: nil)
        }
    }

    @IBAction func onCloseMediaOptionsView(_ sender: Any) {
        hideMediaOptionsView()
    }

    fileprivate func hideMediaOptionsView() {
        UIView.animate(withDuration: 0.3) {
            self.mediaOptionsView.alpha = 0.0
        }
        mediaOptionsView.isHidden = true
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

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if let viewController = segue.destination as? MyBeatsViewController {
            viewController.hideTabs = true
        }

        super.prepare(for: segue, sender: sender)
    }
}

extension ARProfileViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if personalContentButton.isSelected {
            if segmentedControl.selectedSegmentIndex == 0 {
                return videos.array.count
            } else {
                return songs.array.count
            }
        } else {
            if segmentedControl.selectedSegmentIndex == 0 {
                return artists.array.count
            } else if segmentedControl.selectedSegmentIndex == 1 {
                return scoutVideos.array.count
            } else {
                return scoutSongs.array.count
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if personalContentButton.isSelected {
            return cellSize(segmentedControl.selectedSegmentIndex == 0)
        } else {
            if segmentedControl.selectedSegmentIndex == 0 {
                return CGSize(width: collectionView.bounds.width, height: 100)
            } else {
                return cellSize(segmentedControl.selectedSegmentIndex == 1)
            }
        }
    }

    func cellSize(_ isVideo: Bool) -> CGSize {
        if isVideo {
            let width: CGFloat = (view.frame.width / 3.0).rounded(.down)
            let height: CGFloat = (width * 16) / 9
            return CGSize(width: width, height: height)
        } else {
            return CGSize(width: view.frame.width, height: 85)
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if personalContentButton.isSelected {
            if segmentedControl.selectedSegmentIndex == 0 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyVideoCell", for: indexPath) as! VideoCollectionViewCell
                cell.imgPreview.image = mediaPlaceholder
                if let video = videos.array[indexPath.item] as? Video {
                    cell.loadImg(for: video)
                } else {
                    videos.loadVideoDataIfNeeded(uuid: uuid, for: indexPath, collectionView: collectionView)
                }
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SongCell", for: indexPath) as! SongCollectionViewCell
                if let song = songs.array[indexPath.item] as? Song {
                    cell.setup(with: song)
                } else {
                    cell.clear()
                    songs.loadSongDataIfNeeded(uuid: uuid, for: indexPath, collectionView: collectionView)
                }
                return cell
            }
        } else {
            if segmentedControl.selectedSegmentIndex == 0 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ArtistCell", for: indexPath) as! ArtistCollectionViewCell
                if let artist = artists.array[indexPath.item] {
                    if let username = artist.username {
                        cell.username.text = "@\(username)"
                    } else {
                        cell.username.text = ""
                    }
                    if let picture = artist.picture {
                        cell.profile.kf.setImage(with: picture, placeholder: placeholder)
                    } else {
                        cell.profile.image = placeholder
                    }
                    if let uuid = artist.uuid {
                        cell.uuid = uuid
                        if uuid == UserClient.shared.uuid() {
                            cell.button.isHidden = true
                        } else {
                            cell.button.isHidden = false
                            if let amFollowing = artist.amFollowing {
                                cell.amFollowing = amFollowing
                                setFollowUnFollowButton(cell.button, amFollowing: amFollowing)
                            }
                        }
                    } else {
                        cell.uuid = ""
                    }
                } else {
                    cell.username.text = ""
                    cell.profile.image = placeholder
                    cell.uuid = ""
                    cell.button.isHidden = true
                    artists.loadIfNeeded(uuid: uuid, for: indexPath, view: collectionView)
                }
                return cell
            } else if segmentedControl.selectedSegmentIndex == 1 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyVideoCell", for: indexPath) as! VideoCollectionViewCell
                cell.imgPreview.image = mediaPlaceholder
                if let video = scoutVideos.array[indexPath.item] as? Video {
                    cell.loadImg(for: video)
                } else {
                    scoutVideos.loadScoutVideoDataIfNeeded(uuid: uuid, for: indexPath, collectionView: collectionView)
                }
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SongCell", for: indexPath) as! SongCollectionViewCell
                if let song = scoutSongs.array[indexPath.item] as? Song {
                    cell.setup(with: song)
                } else {
                    cell.clear()
                    scoutSongs.loadScoutSongDataIfNeeded(uuid: uuid, for: indexPath, collectionView: collectionView)
                }
                return cell
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if personalContentButton.isSelected {
            if segmentedControl.selectedSegmentIndex == 0 {
                if let video = videos.array[indexPath.item] {
                    playMedia(video)
                }
            } else {
                if let song = songs.array[indexPath.row] as? Song {
                    play(song)
                }
            }
        } else {
            if segmentedControl.selectedSegmentIndex == 0 {
                if let artist = artists.array[indexPath.item], let uuid = artist.uuid, let isANR = artist.isANR {
                    goToProfile(uuid: uuid, arUser: isANR)
                }
            } else if segmentedControl.selectedSegmentIndex == 1 {
                if let video = scoutVideos.array[indexPath.item] {
                    playMedia(video)
                }
            } else {
                if let song = songs.array[indexPath.row] as? Song {
                    play(song)
                }
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

extension ARProfileViewController: AddVocalsToBeatDelegate {
    func didSelectAddVocalsToBeat(viewController: MyBeatsViewController, beat: Beat) {
        self.navigationController?.popViewController(animated: true)
    }

    func didCancel(viewController: MyBeatsViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
}

extension ARProfileViewController: MediaPlayerViewControllerDelegate {
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

