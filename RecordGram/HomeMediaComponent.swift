//
//  HomeMediaComponent.swift
//  RecordGram
//
//  Created by Nicolas Gonzalez on 1/2/18.
//  Copyright © 2018 Meridian Inc. All rights reserved.
//

import PagedArray
import Foundation
import Alamofire

class HomeMediaComponent {
    var array = PagedArray<HomeFeed>(count: 0, pageSize: 0)
    var currentRequest: DataRequest?
    var groups: String
    
    private lazy var pagesLoading = [Int]()
    
    init(_ groups: String) {
        self.groups = groups
    }
    
    func load(collectionView: UICollectionView?) {
        HomeFeedClient.shared.get(groups: groups, page: 1, success: { feed, total, limit in
            guard let count = total, count > 0, let feed = feed else {
                return
            }
            
            self.array = PagedArray<HomeFeed>(count: count, pageSize: limit)
            self.array.set(feed, forPage: 0)
            
            collectionView?.reloadData()
            collectionView?.backgroundColor = UIColor.white
        }, failure: { _ in })
    }
    
    func loadDataIfNeeded(for indexPath: IndexPath, on collectionView: UICollectionView) {
        let currentPage = self.array.page(for: indexPath.row)
        
        guard array.elements[currentPage] == nil else {
            return
        }
        
        guard !pagesLoading.contains(currentPage) else {
            return
        }
        
        pagesLoading.append(currentPage)
        
        currentRequest?.cancel()
        currentRequest = nil
        currentRequest = HomeFeedClient.shared.get(groups: groups, page: currentPage + 1, success: { feed, _, _ in
            self.currentRequest = nil
            self.pagesLoading.removeAll(where: { $0 == currentPage })
            
            guard let feed = feed else {
                return
            }
            
            self.array.set(feed, forPage: currentPage)
            
            collectionView.reloadData()
        }, failure: { error in
            self.currentRequest = nil
            self.pagesLoading.removeAll(where: { $0 == currentPage })
            
            print("HomeMediaComponent Error - \(error.localizedDescription)")
        })
    }
}
