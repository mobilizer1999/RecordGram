//
//  ChatInviteViewController.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 10/11/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.

import UIKit
import PagedArray

class ChatInviteViewController: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var navigationBar: UINavigationBar!

    var array = PagedArray<User>(count: 0, pageSize: 0)
    var pagesLoading = [Int]()
    var indexPaths = [IndexPath]()

    let placeholder = UIImage(named: "profile_placeholder")

    var delegate: ConversationsViewController?

    var searchText = ""
    lazy var searchDebounce = {
        Debouncer(delay: 0.5, callback: search)
    }()

    override func loadView() {
        super.loadView()

        search()
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self

        searchBar.delegate = self

        setupSearchBar()
    }

    @IBAction func onCloseButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    func setupSearchBar() {
        let lineView = UIView(frame: CGRect(x: 0, y: searchBar.frame.size.height - 1, width: searchBar.frame.size.width, height: 1))
        lineView.backgroundColor = UIColor(hex: "EFEFF0")
        searchBar.addSubview(lineView)
        UILabel.appearance(whenContainedInInstancesOf: [UISearchBar.self]).textColor = UIColor(hex: "868b91")
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [NSAttributedStringKey.font.rawValue: UIFont(name: "BebasNeue", size: 30) ?? ""]
    }

    func search() {
        UserClient.shared.followers(query: searchText, page: 1, success: { following, total, limit in
            if let count = total, count > 0, let following = following {
                self.array = PagedArray<User>(count: count, pageSize: limit)
                self.array.set(following, forPage: 0)
                self.tableView.reloadData()
            } else {
                self.array = PagedArray<User>(count: 0, pageSize: 0)
                self.tableView.reloadData()
            }
        }, failure: { error in })
    }
}

extension ChatInviteViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText
        searchDebounce.call()
    }
}

extension ChatInviteViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatInviteTableViewCell") as! ChatInviteTableViewCell

        if let following = array[indexPath.item] {
            if let username = following.username {
                cell.username.text = "@\(username)"
            } else {
                cell.username.text = ""
            }
            if let picture = following.picture {
                cell.picture.kf.setImage(with: picture, placeholder: placeholder)
            } else {
                cell.picture.image = placeholder
            }
            if let isVerified = following.isVerified, isVerified {
                cell.verifiedImageView.isHidden = false
            } else {
                cell.verifiedImageView.isHidden = true
            }
        } else {
            cell.username.text = ""
            cell.picture.image = placeholder
            cell.verifiedImageView.isHidden = true
            indexPaths.append(indexPath)
            let currentPage = array.page(for: indexPath.row)
            if array.elements[currentPage] == nil && !pagesLoading.contains(currentPage) {
                self.pagesLoading.append(currentPage)
                UserClient.shared.followers(query: searchText, page: currentPage + 1, success: { following, _, _ in
                    if let following = following {
                        self.array.set(following, forPage: currentPage)
                        let indexPathsToReload = Array(Set(tableView.indexPathsForVisibleRows! + self.indexPaths)).filter({ self.array.indexes(for: currentPage).contains($0.row) })
                        self.indexPaths = []
                        if indexPathsToReload.count > 0 {
                            tableView.reloadRows(at: indexPathsToReload, with: .automatic)
                        }
                        self.pagesLoading.remove(at: self.pagesLoading.index(of: currentPage)!)
                    }
                }, failure: { error in })
            }
        }


        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let messagesVC = delegate, let item = array[indexPath.item] {
            self.dismiss(animated: true, completion: nil)
            messagesVC.performSegue(withIdentifier: "Chat", sender: item)
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return array.count
    }

}
