//
//  StageMediaComponent.swift
//  RecordGram
//
//  Created by Nicolas Gonzalez on 12/3/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import PagedArray
import Alamofire

class StageMediaComponent {
    var array = PagedArray<HomeFeed>(count: 0, pageSize: 0)
    var currentRequest: DataRequest?
    var groups: String
    
    private lazy var pagesLoading = [Int]()
    
    init(_ groups: String) {
        self.groups = groups
    }
    
    func load(collectionView: UICollectionView) {
        StageClient.shared.get(groups: groups, page: 1, success: { feed, total, limit in
            guard let count = total, count > 0, let feed = feed else {
                return
            }
            
            self.array = PagedArray<HomeFeed>(count: count, pageSize: limit)
            self.array.set(feed, forPage: 0)
            
            collectionView.reloadData()
            collectionView.backgroundColor = UIColor.white
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
        currentRequest = StageClient.shared.get(groups: self.groups, page: currentPage + 1, success: { feed, _, _ in
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
            
            print("StageMediaComponent Error - \(error.localizedDescription)")
        })
    }
}
