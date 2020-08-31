//
//  MenuContentViewController.swift
//  RecordGram
//  Created by Dewayne Perry on 9/20/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import MessageUI
import StoreKit
import Appirater
import AccountKit

struct MenuItem {
    var text: String!
    let icon: UIImage!
    let action: () -> ()
}

class MenuContentViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MFMailComposeViewControllerDelegate {
    var menuItems: [MenuItem] = []
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var profilImage: ProfileUIImageView!
    @IBOutlet weak var verifiedImage: UIImageView!
    
    var mainTabBar: MainTabBarController!
    var homeVC: HomeViewController?
    var musicVC: MusicViewController?
    var studioVC: StudioViewController?
    var creationsVC: CreationsViewController?
    var stageVC: StageViewController?
    var parentVC: MenuViewController?
    fileprivate var accountKit = AKFAccountKit(responseType: .accessToken)


    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        menuItems = [
            MenuItem(text: NSLocalizedString("Notifications", comment: "Menu"), icon: #imageLiteral(resourceName:"menu_notifications"), action: notifications),
            MenuItem(text: NSLocalizedString("Messages", comment: "Menu"), icon: #imageLiteral(resourceName:"menu_messages"), action: messages),
            MenuItem(text: NSLocalizedString("My Studio", comment: "Menu"), icon: #imageLiteral(resourceName:"menu_my_studio"), action: myStudio),
            MenuItem(text: NSLocalizedString("Contests", comment: "Menu"), icon: #imageLiteral(resourceName:"menu_contests"), action: contests),
            MenuItem(text: NSLocalizedString("Find Friends", comment: "Menu"), icon: #imageLiteral(resourceName:"menu_find_friends"), action: findFriends),
            MenuItem(text: NSLocalizedString("Wallet", comment: "Menu"), icon: #imageLiteral(resourceName:"menu_coins"), action: coins),
            MenuItem(text: NSLocalizedString("Affiliation", comment: "Menu"), icon: #imageLiteral(resourceName:"menu_affiliation"), action: affiliation),
//            MenuItem(text: NSLocalizedString("How To Videos", comment: "Menu"), icon: #imageLiteral(resourceName:"menu_how_to_videos"), action: howToVideo),
            MenuItem(text: NSLocalizedString("Rate The App", comment: "Menu"), icon: #imageLiteral(resourceName:"menu_rate_the_app"), action: rateTheApp),
            MenuItem(text: NSLocalizedString("Share The App", comment: "Menu"), icon: #imageLiteral(resourceName:"menu_share_the_app"), action: shareTheApp),
            MenuItem(text: NSLocalizedString("Cre8tor Apps", comment: "Menu"), icon: #imageLiteral(resourceName:"menu_recordgram_apps"), action: recordGramApps),
            MenuItem(text: NSLocalizedString("Contact Us", comment: "Menu"), icon: #imageLiteral(resourceName:"menu_contact_us"), action: contactUs),
            MenuItem(text: NSLocalizedString("Terms Of Service", comment: "Menu"), icon: #imageLiteral(resourceName:"menu_terms_of_service"), action: termsOfService),
            MenuItem(text: NSLocalizedString("Privacy Policy", comment: "Menu"), icon: #imageLiteral(resourceName:"menu_privacy_policy"), action: privacyPolicy),
            MenuItem(text: NSLocalizedString("Sign Out", comment: "Menu"), icon: #imageLiteral(resourceName:"menu_sign_out"), action: menuSignOut),
        ]
        
        UserClient.shared.get("is_verified") { isVerified in
            self.verifiedImage.isHidden = isVerified == "0"
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTapImageProfile))
        profilImage.addGestureRecognizer(tapGesture)
    }

    @objc func onTapImageProfile() {
        ((UIApplication.shared.delegate as! AppDelegate).mainTab?.selectedViewController as? UINavigationController)?.topViewController?.goToMyProfile()
        parentVC?.hideMenu()
    }
    
    func menuSignOut() {
        parentVC?.hideMenu()
        signOut()
    }


    func configureTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        let inset = UIEdgeInsetsMake(0, 0, 20, 0)
        tableView.contentInset = inset
    }

    func notifications() {
        let storyBoard = UIStoryboard(name: "Menu", bundle: nil)
        let notificationsVC = storyBoard.instantiateViewController(withIdentifier: "NotificationsViewController") as! NotificationsViewController
        homeVC?.navigationController?.pushViewController(notificationsVC, animated: true)
        musicVC?.navigationController?.pushViewController(notificationsVC, animated: true)
        studioVC?.navigationController?.pushViewController(notificationsVC, animated: true)
        creationsVC?.navigationController?.pushViewController(notificationsVC, animated: true)
        stageVC?.navigationController?.pushViewController(notificationsVC, animated: true)
        parentVC?.hideMenu()
    }

    func messages() {
        let storyBoard = UIStoryboard(name: "Messages", bundle: nil)
        let messagesVC = storyBoard.instantiateViewController(withIdentifier: "ConversationsViewController") as! ConversationsViewController
        homeVC?.navigationController?.pushViewController(messagesVC, animated: true);
        musicVC?.navigationController?.pushViewController(messagesVC, animated: true)
        studioVC?.navigationController?.pushViewController(messagesVC, animated: true)
        creationsVC?.navigationController?.pushViewController(messagesVC, animated: true)
        stageVC?.navigationController?.pushViewController(messagesVC, animated: true)
        parentVC?.hideMenu()
    }

    func myStudio() {
        goToStudioAndPresentMyStudio()
        parentVC?.hideMenu()
    }

    func contests() {
        let storyBoard = UIStoryboard(name: "Contests", bundle: nil)
        let contestsVC = storyBoard.instantiateViewController(withIdentifier: "ContestsViewController") as! ContestsViewController
        homeVC?.navigationController?.pushViewController(contestsVC, animated: true)
        musicVC?.navigationController?.pushViewController(contestsVC, animated: true)
        studioVC?.navigationController?.pushViewController(contestsVC, animated: true)
        creationsVC?.navigationController?.pushViewController(contestsVC, animated: true)
        stageVC?.navigationController?.pushViewController(contestsVC, animated: true)
        parentVC?.hideMenu()
    }

    func findFriends() {
        let storyBoard = UIStoryboard(name: "Menu", bundle: nil)
        let findFollowVC = storyBoard.instantiateViewController(withIdentifier: "FindFollowTableViewController") as! FindFollowTableViewController
        homeVC?.navigationController?.pushViewController(findFollowVC, animated: true)
        musicVC?.navigationController?.pushViewController(findFollowVC, animated: true)
        studioVC?.navigationController?.pushViewController(findFollowVC, animated: true)
        creationsVC?.navigationController?.pushViewController(findFollowVC, animated: true)
        stageVC?.navigationController?.pushViewController(findFollowVC, animated: true)
        parentVC?.hideMenu()
    }

    func coins() {
        openCoinsPopover()
        parentVC?.hideMenu()
    }

    func affiliation() {
        let storyBoard = UIStoryboard(name: "Menu", bundle: nil)
        let affiliateVC = storyBoard.instantiateViewController(withIdentifier: "AffiliateViewController") as! AffiliateViewController
        affiliateVC.modalPresentationStyle = .overCurrentContext
        affiliateVC.homeVC = homeVC
        present(affiliateVC, animated: true, completion: nil)
        parentVC?.hideMenu()
    }

    func howToVideo() {
        let storyBoard = UIStoryboard(name: "Menu", bundle: nil)
        let vc = storyBoard.instantiateViewController(withIdentifier: "HowToVideosViewController") as! HowToVideosViewController
        homeVC?.navigationController?.pushViewController(vc, animated: true)
        musicVC?.navigationController?.pushViewController(vc, animated: true)
        studioVC?.navigationController?.pushViewController(vc, animated: true)
        creationsVC?.navigationController?.pushViewController(vc, animated: true)
        stageVC?.navigationController?.pushViewController(vc, animated: true)
        parentVC?.hideMenu()
    }

    func rateTheApp() {
        if #available(iOS 10.3, *) {
            SKStoreReviewController.requestReview()
        } else {
            // Fallback on earlier versions
            Appirater.appLaunched(true)
            Appirater.setAppId("1126223607")
            Appirater.setDaysUntilPrompt(10)
            Appirater.setUsesUntilPrompt(10)
            Appirater.setSignificantEventsUntilPrompt(-1)
            Appirater.setTimeBeforeReminding(3)
            Appirater.setDebug(true)
        }
        parentVC?.hideMenu()
    }

    func shareTheApp() {
        let invitationMessage = NSLocalizedString("Try this amazing app on the App Store!", comment: "Share")
        let invitationURL = "https://appsto.re/in/37midb.i"
        let items = [invitationMessage, invitationURL] as [Any]

        let shareActivityController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        shareActivityController.popoverPresentationController?.sourceView = self.view
        self.present(shareActivityController, animated: true, completion: nil)
        parentVC?.hideMenu()
    }

    func recordGramApps() {
        guard let appStorePageURL = URL(string: "https://itunes.apple.com/in/developer/recordgram-inc/id1126223606") else {
            return
        }
        let application = UIApplication.shared
        if application.canOpenURL(appStorePageURL) {
            application.open(appStorePageURL, options: [:], completionHandler: nil)
        }
    }

    func contactUs() {
        let composeVC = MFMailComposeViewController()
        composeVC.mailComposeDelegate = self

        // TODO: 2018-04-16 refactor 
        if !MFMailComposeViewController.canSendMail() {
            print("Mail services are not available")
            return
        } else {
            // Configure the fields of the interface.
            composeVC.setToRecipients(["support@recordgram.com"])
            composeVC.setSubject("Cre8tor Support")
            composeVC.navigationBar.tintColor = UIColor.primary 
//            composeVC.setMessageBody("Hello from Seattle!", isHTML: false)

            // Present the view controller modally.
            self.present(composeVC, animated: true, completion: nil)
        }

    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {

//        if result == .cancelled {
//            self.dismiss(animated: controller, completion: nil)
//        }
        self.dismiss(animated: true, completion: nil)
    }

    func termsOfService() {
        let storyboard = UIStoryboard.init(name: "Menu", bundle: nil)
        let termsOfServiceVC = storyboard.instantiateViewController(withIdentifier: "TermsOfServiceViewController") as! TermsOfServiceViewController
        homeVC?.navigationController?.pushViewController(termsOfServiceVC, animated: true)
        musicVC?.navigationController?.pushViewController(termsOfServiceVC, animated: true)
        studioVC?.navigationController?.pushViewController(termsOfServiceVC, animated: true)
        creationsVC?.navigationController?.pushViewController(termsOfServiceVC, animated: true)
        stageVC?.navigationController?.pushViewController(termsOfServiceVC, animated: true)
        parentVC?.hideMenu()
    }

    func privacyPolicy() {
        let storyboard = UIStoryboard.init(name: "Menu", bundle: nil)
        let privacyPolicyVC = storyboard.instantiateViewController(withIdentifier: "PrivacyPolicyViewController") as! PrivacyPolicyViewController
        homeVC?.navigationController?.pushViewController(privacyPolicyVC, animated: true)
        musicVC?.navigationController?.pushViewController(privacyPolicyVC, animated: true)
        studioVC?.navigationController?.pushViewController(privacyPolicyVC, animated: true)
        creationsVC?.navigationController?.pushViewController(privacyPolicyVC, animated: true)
        stageVC?.navigationController?.pushViewController(privacyPolicyVC, animated: true)
        parentVC?.hideMenu()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let i = indexPath.row
        menuItems[i].action()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let i = indexPath.row
        let cell = tableView.dequeueReusableCell(withIdentifier: "item", for: indexPath)
        cell.textLabel?.text = menuItems[i].text
        cell.imageView?.image = menuItems[i].icon
        return cell
    }


}
