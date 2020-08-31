//
//  UserSearchViewController.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/23/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.

import UIKit

class UserSearchViewController: UIViewController {
    
    var userSearchTableViewController: UserSearchTableViewController! = nil
    var recentSearchHistoryTableViewController: RecentSearchHistoryTableViewController! = nil
    var rgTransitionDelegate = RGTransitioningDelegate()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSearchBar()
//        setupUserSearchTVC()
        setupRecentSearchHistoryTVC()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        recentSearchHistoryTableViewController.view.frame = CGRect(x: 0, y: 100, width: screenWidth, height: screenHeight - 100)
//        userSearchTableViewController.view.frame =  CGRect(x: 0, y: 100, width: screenWidth, height: screenHeight - 100)

    }
    
    func setupUserSearchTVC() {
        userSearchTableViewController = UserSearchTableViewController(style: .plain)
        self.addChildViewController(userSearchTableViewController)
        userSearchTableViewController.didMove(toParentViewController: self)
        self.view.addSubview(userSearchTableViewController.view)
        userSearchTableViewController.view.backgroundColor = .black
    }
    
    func setupRecentSearchHistoryTVC() {
        recentSearchHistoryTableViewController = RecentSearchHistoryTableViewController(style: .plain)
        self.addChildViewController(recentSearchHistoryTableViewController)
        recentSearchHistoryTableViewController.didMove(toParentViewController: self)
        self.view.addSubview(recentSearchHistoryTableViewController.view)
    }
    
    
    func setupSearchBar() {
        let storyboard = UIStoryboard.init(name: "Helpers", bundle: nil)
        let searchBarVC = storyboard.instantiateViewController(withIdentifier: "SearchBarViewController") as! SearchBarViewController
        searchBarVC.transitioningDelegate = rgTransitionDelegate
        searchBarVC.modalPresentationStyle = .custom
        
        addChildViewController(searchBarVC)
        UIView.animate(withDuration: 0.3, animations: {() -> Void in
            searchBarVC.view.frame = CGRect(x: 0, y: 0, width:  self.view.frame.size.width, height: 100)
        }, completion: {(_ finished: Bool) -> Void in
            searchBarVC.didMove(toParentViewController: self)
            self.view.addSubview(searchBarVC.view)
        })
    }

    
    
    
    
}
