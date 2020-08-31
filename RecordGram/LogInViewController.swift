//
//  LogInViewController.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/11/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import AVFoundation
import AccountKit
import FBSDKLoginKit
import UserNotifications
import MessageUI

class LogInViewController: UIViewController, ErrorHandler {

    @IBOutlet weak var phoneLogInButton: RoundButton!
    @IBOutlet weak var emailLogInButton: RoundButton!
    @IBOutlet weak var btnContactSupport: RoundButton!
    @IBOutlet weak var termsConditionsButton: UIButton!
    @IBOutlet weak var privacyPolicyButton: UIButton!

    fileprivate var accountKit = AKFAccountKit(responseType: .authorizationCode)
    let userDefaults = UserDefaults.standard
    var avPlayer: AVPlayer?
    var avPlayerLayer: AVPlayerLayer?
    var paused: Bool = false
    var splashView: UIView!
    var splashLogoImg: UIImageView!
    
    override func loadView() {
        super.loadView()
        
        setupButtonsUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if userDefaults.string(forKey: kJWTKey) != nil {
            setupNotifications()
            // Dummy Splash View
            showSplash()
            guard let username = userDefaults.string(forKey: kUserNameKey), !username.isEmpty else {
                self.presentChooseUsernameVC()
                return
            }
            presentMainTabBar()
        } else {
            setupVideoPlayer()
            if let viewController = accountKit.viewControllerForLoginResume() {
                prepareDataEntryViewController(viewController)
                present(viewController, animated: false)
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        avPlayer?.play()
        paused = false
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        avPlayer?.pause()
        paused = true
    }

    @objc func playerItemDidReachEnd(notification: Notification) {
        guard let p: AVPlayerItem = notification.object as? AVPlayerItem else {
            return
        }
        p.seek(to: kCMTimeZero)
    }

    fileprivate func setupVideoPlayer() {
        navigationController?.navigationBar.isHidden = true
        guard let theURL = Bundle.main.url(forResource: "LogInVideo", withExtension: "mp4") else {
            return
        }

        if let player = avPlayer {
            player.seek(to: kCMTimeZero, completionHandler: { _ in
                player.play()
            })
        } else {
            avPlayer = AVPlayer(url: theURL)
            avPlayerLayer = AVPlayerLayer(player: avPlayer)
            avPlayerLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            avPlayer?.volume = 0
            avPlayer?.actionAtItemEnd = .none
            
            avPlayerLayer?.frame = view.layer.bounds
            view.backgroundColor = .clear
            view.layer.insertSublayer(avPlayerLayer!, at: 0)
            
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(playerItemDidReachEnd(notification:)),
                                                   name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                                   object: avPlayer?.currentItem)
        }
        
    }

    fileprivate func setupButtonsUI() {
        emailLogInButton.applyBlurEffect()
        phoneLogInButton.applyBlurEffect()
        btnContactSupport.applyBlurEffect()

        let attributes: [NSAttributedStringKey: Any] = [NSAttributedStringKey.underlineStyle: (1), NSAttributedStringKey.foregroundColor: UIColor.white]
        termsConditionsButton.setAttributedTitle(NSAttributedString(string: NSLocalizedString("Terms & Conditions", comment: "Login"), attributes: attributes), for: .normal)
        privacyPolicyButton.setAttributedTitle(NSAttributedString(string: NSLocalizedString("Privacy Policy", comment: "Login"), attributes: attributes), for: .normal)
    }

    fileprivate func presentMainTabBar() {
        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "MainTabBarController") as! MainTabBarController
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.mainTab = viewController
        self.present(viewController, animated: false)
    }

    fileprivate func presentChooseUsernameVC() {
        let viewController = self.storyboard?.instantiateViewController(withIdentifier: "ChooseUsernameViewController") as! ChooseUsernameViewController
        self.present(viewController, animated: false, completion: nil)
    }

    func prepareDataEntryViewController(_ loginViewController: AKFViewController) {
        loginViewController.delegate = self as AKFViewControllerDelegate
        let theme: AKFTheme = AKFTheme.default()
        theme.headerBackgroundColor = UIColor.rgb(red: 57, green: 4, blue: 54, alpha: 1)
        theme.headerTextColor = UIColor.white
        theme.iconColor = UIColor(red: 0.325, green: 0.557, blue: 1, alpha: 1)
        theme.inputTextColor = UIColor.rgb(red: 57, green: 4, blue: 54, alpha: 1)
        theme.statusBarStyle = .default
        theme.textColor = UIColor.lightText
        theme.titleColor = UIColor.white
        theme.backgroundColor = UIColor.rgb(red: 57, green: 4, blue: 54, alpha: 1)
        theme.buttonBackgroundColor = UIColor.rgb(red: 194, green: 10, blue: 122, alpha: 1.0)
        theme.buttonBorderColor = UIColor.rgb(red: 194, green: 10, blue: 122, alpha: 1.0)
        loginViewController.setTheme(theme)
    }

    func createSplashViews() {
        let SCREEN_WIDTH = UIScreen.main.bounds.size.width
        let SCREEN_HEIGHT = UIScreen.main.bounds.size.height

        splashView = UIView(frame: CGRect(x: 0, y: 0, width: CGFloat(SCREEN_WIDTH), height: CGFloat(SCREEN_HEIGHT)))
        splashView.backgroundColor = UIColor(hex: "390436")
        let size: CGFloat = 200
        splashLogoImg = UIImageView(frame: CGRect(x: (SCREEN_WIDTH - size) / 2, y: (SCREEN_HEIGHT - size) / 2, width: size, height: size))
        splashLogoImg.image = UIImage(named: "color-logo")
        splashLogoImg.contentMode = .scaleAspectFit
        splashView.addSubview(splashLogoImg)

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window?.addSubview(splashView)
    }

    func showSplash() {
        createSplashViews()

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.3 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: { () -> Void in
            self.scaleSplashLogo()
        })
    }

    func scaleSplashLogo() {
        UIView.animate(withDuration: 0.8, delay: 0.0, options: [.allowUserInteraction, .beginFromCurrentState], animations: { () -> Void in
            self.splashLogoImg.transform = CGAffineTransform(scaleX: 0.70, y: 0.70)
        }, completion: { (_ finished: Bool) -> Void in
            UIView.animate(withDuration: 0.7, animations: { () -> Void in
                self.splashView.alpha = 0.0
                self.splashLogoImg.transform = CGAffineTransform(scaleX: 10, y: 10)
            }, completion: { (_ finished: Bool) -> Void in
                self.splashView.removeFromSuperview()
            })
        })
    }

    @IBAction func loginWithPhone(_ sender: Any) {
        let viewController = accountKit.viewControllerForPhoneLogin()

        prepareDataEntryViewController(viewController)
        present(viewController, animated: true, completion: nil)
    }

    @IBAction func loginWithEmail(_ sender: Any) {
        let viewController = accountKit.viewControllerForEmailLogin()

        prepareDataEntryViewController(viewController)
        present(viewController, animated: true, completion: nil)
    }
    
    @IBAction func didTapContactSupportButton(_ sender: Any) {
        if !MFMailComposeViewController.canSendMail() {
            let viewController = UIAlertController(title: NSLocalizedString("Cre8tor.app", comment: "No mail account dialog title"), message: NSLocalizedString("No mail account detected. Make sure you have one going to your iPhone Settings > Mail", comment: "No mail account dialog body"), preferredStyle: .alert)
            viewController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "No mail account dialog confirmation"), style: .default, handler: nil))
            
            present(viewController, animated: true, completion: nil)
            
            return
        }
        
        let viewController = MFMailComposeViewController()
        viewController.setToRecipients(["support@cre8tor.app"])
        viewController.setSubject(NSLocalizedString("Cre8tor.app - Support", comment: "Support email subject"))
        viewController.mailComposeDelegate = self
        viewController.navigationBar.tintColor = UIColor.white        
        present(viewController, animated: true, completion: nil)
    }
}

extension LogInViewController: AKFViewControllerDelegate {
    func viewController(_ viewController: (UIViewController & AKFViewController)!, didCompleteLoginWithAuthorizationCode code: String!, state: String!) {
        AuthClient().login(authCode: code, success: { decodedJWT in
            self.setupNotifications()

            self.dismiss(animated: true, completion: nil)

            guard let username = decodedJWT["username"] as? String, !username.isEmpty else {
                self.presentChooseUsernameVC()
                return
            }

            self.userDefaults.set(username, forKey: kUserNameKey)
            self.presentMainTabBar()
        }, failure: { error in
            self.presentErrorDialog(error: error)
        })
    }

    func viewController(_ viewController: (UIViewController & AKFViewController)!, didFailWithError error: Error!) {
        presentErrorDialog(error: error as NSError)
    }
}

extension LogInViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        dismiss(animated: true, completion: nil)
    }
}
