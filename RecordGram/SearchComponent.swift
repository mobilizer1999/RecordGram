//
// Created by Nicolas Gonzalez on 11/21/17.
// Copyright (c) 2017 Meridian Inc. All rights reserved.
//

import UIKit
import PagedArray
import Alamofire
import SwiftyJSON

class SearchComponent {
    private var items = PagedArray<JSON>(count: 0, pageSize: 0)
    private var currentRequest: DataRequest?
    private var groups: String
    
    private lazy var pagesLoading = [Int]()
    
    init(groups: String) {
        self.groups = groups
    }
    
    func count() -> Int {
        return items.count
    }
    
    func item(at indexPath: IndexPath) -> JSON? {
        return items[indexPath.item]
    }
    
    func search(_ query: String, containerView: UIView, collectionView: UICollectionView) {
        func hide() {
            items = PagedArray<JSON>(count: 0, pageSize: 0)
            
            containerView.isHidden = true
            collectionView.reloadData()
        }
        
        if query.count <= 2 {
            hide()
            
            return
        }
        
        SearchClient.shared.get(query: query, groups: self.groups, page: 1, success: { response, total, limit in
            guard let total = total, total > 0 else {
                hide()
                return
            }
            
            self.items = PagedArray<JSON>(count: total, pageSize: limit)
            self.items.set(response["data"].arrayValue, forPage: 0)
            
            containerView.isHidden = false
            collectionView.reloadData()
            
            UserDefaults.standard.set(query, forKey: kRecentSearchesKey)
        }, failure: { _ in })
    }
    
    func loadDataIfNeeded(_ query: String, for indexPath: IndexPath, on collectionView: UICollectionView) {
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
        currentRequest = SearchClient.shared.get(query: query, groups: self.groups, page: currentPage + 1, success: { response, _, _ in
            self.currentRequest = nil
            self.pagesLoading.removeAll(where: { $0 == currentPage })
            
            self.items.set(response["data"].arrayValue, forPage: currentPage)
            
            collectionView.reloadData()
        }, failure: { error in
            self.currentRequest = nil
            self.pagesLoading.removeAll(where: { $0 == currentPage })
            
            print("SearchComponent Error - \(error.localizedDescription)")
        })
    }
}
