//
//  TermsOfServiceViewController.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/27/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.

import UIKit
import WebKit

class TermsOfServiceViewController: UIViewController, ErrorHandler, WKUIDelegate {

    var webView: WKWebView!

    override func loadView() {
        super.loadView()

//        SettingsClient.shared.terms(success: { terms in
//            print("AppDebug", terms)
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

        let myURL = URL(string: "https://www.recordgram.com/API/public/settings_file/Terms_RecordGram.pdf")
        let myRequest = URLRequest(url: myURL!)

        webView.load(myRequest)

        self.title = NSLocalizedString("Terms Of Service", comment: "Terms of Service")
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "backArrow"), style: .plain, target: self, action: #selector(TermsOfServiceViewController.onCloseButton))
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
