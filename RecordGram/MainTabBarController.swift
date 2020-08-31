//
//  MainTabBarController.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/12/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import AccountKit
import CoreMedia

class MainTabBarController: UITabBarController {

    // MARK: Properties
    fileprivate var accountKit = AKFAccountKit(responseType: .accessToken)
    fileprivate var dataEntryViewController: AKFViewController? = nil
    fileprivate var showAccountOnAppear = false

    private var mediaPlayer: MediaPlayer?
    private var playerView: PlayerView?
    private var exitButton: UIButton?

    var shouldShowTour = false
    var isShowingExit = false

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tabBar.items?.forEach({ (item) in
            item.image = item.image?.withRenderingMode(.alwaysOriginal)
            item.selectedImage = item.selectedImage?.withRenderingMode(.alwaysOriginal)
        })
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if shouldShowTour {
            showTour()
        }
    }

    fileprivate func presentLoginViewController() {
        let storyBoard = UIStoryboard.init(name: "LogIn", bundle: nil)
        let viewController = storyBoard.instantiateViewController(withIdentifier: "LogInViewController") as! LogInViewController
        navigationController?.pushViewController(viewController, animated: true)
    }

    func goToStudioAndShowMyStudio() {
        self.selectedIndex = 2

        let studioNavVC = self.viewControllers![2] as! UINavigationController
        studioNavVC.popToRootViewController(animated: false)
        let studioVC = studioNavVC.viewControllers[0] as! StudioViewController
        studioVC.showMyStudio()
    }

    func showTour() {
        guard let tourUrl = Bundle.main.url(forResource: "NewIntroVideo720", withExtension: "mp4") else {
            return
        }

        mediaPlayer = MediaPlayer(url: tourUrl)

        guard let mediaPlayer = mediaPlayer else {
            return
        }

        mediaPlayer.delegate = self

        playerView = PlayerView()

        guard let playerView = playerView else {
            return
        }

        playerView.frame = UIScreen.main.bounds

        let gesture = UITapGestureRecognizer(target: self, action: #selector(MainTabBarController.toggleExit))
        gesture.numberOfTapsRequired = 1
        gesture.numberOfTouchesRequired = 1

        playerView.addGestureRecognizer(gesture)

        exitButton = UIButton()

        guard let exitButton = exitButton else {
            return
        }

        exitButton.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        exitButton.layer.cornerRadius = 10

        exitButton.addTarget(self, action: #selector(MainTabBarController.closeTour), for: .touchUpInside)
        exitButton.setTitle(NSLocalizedString("Exit Tour", comment: "Intro"), for: .normal)
        playerView.addSubview(exitButton)

        setExitButtonTop(by: -100)

        mediaPlayer.playerView = playerView
    }

    func setExitButtonTop(by offset: CGFloat) {
        if let exitButton = exitButton, let playerView = playerView {
            var frame = playerView.frame

            if #available(iOS 11.0, *) {
                frame = view.safeAreaLayoutGuide.layoutFrame
            }

            exitButton.frame = CGRect(
                    x: frame.width / 2 - 50,
                    y: frame.minY + offset,
                    width: 100,
                    height: 30
            )
        }
    }

    @objc func toggleExit() {
        UIView.animate(withDuration: 0.3) {
            self.setExitButtonTop(by: self.isShowingExit ? -100 : 50)
        }
        isShowingExit = !isShowingExit
    }

    @objc func closeTour() {
        guard let mediaPlayer = mediaPlayer else {
            return
        }
        mediaPlayer.playerView?.removeFromSuperview()
        mediaPlayer.playerView = nil
        mediaPlayer.stop()
        self.mediaPlayer = nil
        self.playerView = nil

        openFindYourFriends()
    }

    func openFindYourFriends() {
        let storyboard = UIStoryboard.init(name: "Menu", bundle: nil)
        let findYourFriendsViewController = storyboard.instantiateViewController(withIdentifier: "FindYourFriendsViewController") as! FindYourFriendsViewController
        findYourFriendsViewController.modalPresentationStyle = .overCurrentContext
        findYourFriendsViewController.mainTabBarController = self
        self.present(findYourFriendsViewController, animated: true, completion: nil)
    }
}

extension MainTabBarController: MediaPlayerDelegate {
    func onReadyToPlay(player: MediaPlayer) {
        if let playerView = playerView {
            let window = UIApplication.shared.keyWindow!
            window.addSubview(playerView)
            playerView.makeToast(NSLocalizedString("Let's Have a Tour!", comment: "Intro"), duration: 3, position: .top)
        }
    }

    func onPeriodicTimeObserver(player: MediaPlayer, time: CMTime) {
    }

    func didPlayToEndTime(player: MediaPlayer) {
        closeTour()
    }

    func didStartPlaying(player: MediaPlayer) {
    }

    func onFailure(error: Error) {
        print(error.localizedDescription)
    }
}
