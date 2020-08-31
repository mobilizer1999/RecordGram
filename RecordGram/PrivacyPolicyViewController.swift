//
//  PrivacyPolicyViewController.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/27/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.

import UIKit
import WebKit

class PrivacyPolicyViewController: UIViewController, ErrorHandler, WKUIDelegate {

    var webView: WKWebView!

    override func loadView() {
        super.loadView()

//        SettingsClient.shared.privacy(success: { privacy in
//            print("AppDebug", privacy)
//        }, failure: { error in
//            self.presentErrorDialog(error: error)
//        })
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let myURL = URL(string: "https://www.recordgram.com/API/public/settings_file/Privacy_Policy_RecordGram.pdf")
        let myRequest = URLRequest(url: myURL!)

        webView.load(myRequest)

        self.title = NSLocalizedString("Privacy Policy", comment: "Privacy Policy")
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "backArrow"), style: .plain, target: self, action: #selector(PrivacyPolicyViewController.onCloseButton))
        automaticallyAdjustsScrollViewInsets = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
        self.tabBarController?.tabBar.isTranslucent = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    @objc func onCloseButton() {
         navigationController?.popViewController(animated: true)
    }
}
