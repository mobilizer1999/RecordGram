//
//  SearchBarViewController.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/13/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import SwiftyJSON

class SearchBarViewController: UIViewController, UISearchBarDelegate {
    let statusBarHeight = 20

    var searchResults: SearchResultsViewController!

    @IBOutlet weak var searchBar: UISearchBar!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSearchBar()
        searchBar.delegate = self

        searchResults = self.parent as! SearchResultsViewController;
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.searchBar.isTranslucent = false
        self.searchBar.backgroundImage = UIImage()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchBar.becomeFirstResponder()

    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        searchBar.resignFirstResponder()
    }

    func setupSearchBar() {
        searchBar.frame = CGRect(x: 0, y: statusBarHeight, width: Int(self.view.frame.size.width), height: (100 - statusBarHeight))
        let rect: CGRect = searchBar.frame
        let lineView = UIView(frame: CGRect(x: 0, y: rect.size.height - 2, width: rect.size.width, height: 2))
        lineView.backgroundColor = UIColor.white
        searchBar.addSubview(lineView)

        UILabel.appearance(whenContainedInInstancesOf: [UISearchBar.self]).textColor = UIColor(hex: "e6ebf1")
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [NSAttributedStringKey.font.rawValue: UIFont(name: "BebasNeue", size: 30) ?? ""]
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).clearButtonMode = .never

        view.backgroundColor = UIColor.white
        searchBar.showsCancelButton = false
        searchBar.layer.borderColor = UIColor.white.cgColor
        searchBar.showsSearchResultsButton = false
        searchBar.tintColor = UIColor(hex: "34455a")
        searchBar.showsScopeBar = false
        searchBar.barTintColor = UIColor.white
    }

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        return true
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    @IBAction func onCloseButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchResults.search(searchText)
    }
}
