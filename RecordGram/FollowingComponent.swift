//
//  FollowingComponent.swift
//  RecordGram
//
//  Created by Nicolas Gonzalez on 1/17/18.
//  Copyright © 2018 Meridian Inc. All rights reserved.
//

import PagedArray
import Foundation

class FollowingComponent {

    var array = PagedArray<User>(count: 0, pageSize: 0)
    var pagesLoading = [Int]()
    var indexPaths = [IndexPath]()

    func load(uuid: String, view: UIView?) {
        UserClient.shared.following(for: uuid, page: 1, success: { following, total in
            if let count = total, count > 0, let following = following {
                self.array = PagedArray<User>(count: count, pageSize: 15)
                self.array.set(following, forPage: 0)
                if let collectionView = view as? UICollectionView {
                    collectionView.reloadData()
                } else if let tableView = view as? UITableView {
                    tableView.reloadData()
                }
            }
        }, failure: { error in })
    }

    func loadIfNeeded(uuid: String, for indexPath: IndexPath, view: UIView) {
        indexPaths.append(indexPath)
        let currentPage = array.page(for: indexPath.row)
        if array.elements[currentPage] == nil && !pagesLoading.contains(currentPage) {
            self.pagesLoading.append(currentPage)
            UserClient.shared.following(for: uuid, page: currentPage + 1, success: { following, _ in
                if let following = following {
                    self.array.set(following, forPage: currentPage)
                    if let collectionView = view as? UICollectionView {
                        let indexPathsToReload = Array(Set(collectionView.indexPathsForVisibleItems + self.indexPaths)).filter({ self.array.indexes(for: currentPage).contains($0.row) })
                        if indexPathsToReload.count > 0 {
                            collectionView.reloadItems(at: indexPathsToReload)
                        }
                    } else if let tableView = view as? UITableView {
                        let indexPathsToReload = Array(Set(tableView.indexPathsForVisibleRows! + self.indexPaths)).filter({ self.array.indexes(for: currentPage).contains($0.row) })
                        if indexPathsToReload.count > 0 {
                            tableView.reloadRows(at: indexPathsToReload, with: .automatic)
                        }
                    }
                    self.indexPaths = []
                    self.pagesLoading.remove(at: self.pagesLoading.index(of: currentPage)!)
                }
            }, failure: { error in })
        }
    }
}
