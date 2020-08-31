//
//  NotificationComponent.swift
//  RecordGram
//
//  Created by Hugo Prione on 27/09/18.
//  Copyright © 2018 Meridian Inc. All rights reserved.
//

import UIKit
import PagedArray
import Alamofire

class NotificationComponent {
    private var items = PagedArray<RGNotification>(count: 0, pageSize: 0)
    private var currentRequest: DataRequest?
    
    private lazy var pagesLoading = [Int]()
    
    func count() -> Int {
        return items.count
    }
    
    func item(at indexPath: IndexPath) -> RGNotification? {
        return items[indexPath.row]
    }
    
    func clear() {
        items.removeAllPages()
        items.count = -1
        items = PagedArray<RGNotification>(count: 0, pageSize: 0)
    }
    
    func load(tableView: UITableView) {
        NotificationsClient.shared.get(page: 1, success: { feed, total, limit in
            guard let count = total, count > 0, let feed = feed else {
                return
            }
            
            self.items = PagedArray<RGNotification>(count: count, pageSize: limit)
            self.items.set(feed, forPage: 0)
            
            tableView.reloadData()
            tableView.backgroundColor = UIColor.white
            
            NotificationsClient.shared.readAll()
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
        currentRequest = NotificationsClient.shared.get(page: currentPage + 1, success: { feed, _, _ in
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
            
            print("NotificationComponent Error - \(error.localizedDescription)")
        })
    }
}
