//
//  FansMediaComponent.swift
//  RecordGram
//
//  Created by Hugo Prione on 27/09/18.
//  Copyright © 2018 Meridian Inc. All rights reserved.
//

import UIKit
import PagedArray
import Alamofire

class FansMediaComponent {
    private var items = PagedArray<User>(count: 0, pageSize: 0)
    private var currentRequest: DataRequest?
    private var uuid: String
    
    private lazy var pagesLoading = [Int]()
    
    init(uuid: String) {
        self.uuid = uuid
    }
    
    func count() -> Int {
        return items.count
    }
    
    func item(at indexPath: IndexPath) -> User? {
        return items[indexPath.row]
    }
    
    func load(tableView: UITableView) {
        UserClient.shared.followers(for: uuid, page: 1, success: { feed, total, limit in
            guard let count = total, count > 0, let feed = feed else {
                return
            }
            
            self.items = PagedArray<User>(count: count, pageSize: limit)
            self.items.set(feed, forPage: 0)
            
            tableView.reloadData()
            tableView.backgroundColor = UIColor.white
        }, failure: { _ in })
    }
    
    func loadDataIfNeeded(for indexPath: IndexPath, on tableView: UITableView) {
        let currentPage = self.items.page(for: indexPath.row)
        
        guard items.elements[currentPage] == nil else {
            return
        }
        
        guard !pagesLoading.contains(currentPage) else {
            return
        }
        
        pagesLoading.append(currentPage)
        
        currentRequest?.cancel()
        currentRequest = nil
        currentRequest = UserClient.shared.followers(for: uuid, page: currentPage + 1, success: { feed, _, _ in
            self.currentRequest = nil
            self.pagesLoading.removeAll(where: { $0 == currentPage })
            
            guard let feed = feed else {
                return
            }
            
            self.items.set(feed, forPage: currentPage)
            
            tableView.reloadData()
        }, failure: { error in
            self.currentRequest = nil
            self.pagesLoading.removeAll(where: { $0 == currentPage })
            
            print("FansMediaComponent Error - \(error.localizedDescription)")
        })
    }
}
