//
//  BlockedUsersTableViewController.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/8/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import PagedArray

class BlockedUsersTableViewController: UITableViewController {

    var array = PagedArray<User>(count: 0, pageSize: 0)
    var pagesLoading = [Int]()
    var indexPaths = [IndexPath]()

    let placeholder = UIImage(named: "profile_placeholder")

    override func loadView() {
        super.loadView()

        UserClient.shared.blocked(page: 1, success: { users, total in
            if let count = total, count > 0, let users = users {
                self.array = PagedArray<User>(count: count, pageSize: 15)
                self.array.set(users, forPage: 0)
                self.tableView.reloadData()
            }
        }, failure: { error in })
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        noTabs()
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.array.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "blockedUsersTableViewCell", for: indexPath) as? BlockedUsersTableViewCell else {
            abort()
        }
        
        if let follower = array[indexPath.item] {
            if let username = follower.username {
                cell.lblName.text = "@\(username)"
            } else {
                cell.lblName.text = ""
            }
            if let picture = follower.picture {
                cell.imgProfile.kf.setImage(with: picture, placeholder: placeholder)
            } else {
                cell.imgProfile.image = placeholder
            }
            if let uuid = follower.uuid {
                cell.uuid = uuid
            } else {
                cell.uuid = ""
            }
        } else {
            cell.lblName.text = ""
            cell.imgProfile.image = placeholder
            cell.uuid = ""
            indexPaths.append(indexPath)
            let currentPage = array.page(for: indexPath.row)
            if array.elements[currentPage] == nil && !pagesLoading.contains(currentPage) {
                self.pagesLoading.append(currentPage)
                UserClient.shared.blocked(page: currentPage + 1, success: { users, _ in
                    if let users = users {
                        self.array.set(users, forPage: currentPage)
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
}
