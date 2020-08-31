//
//  GenresMediaComponent.swift
//  RecordGram
//
//  Created by Hugo Prione on 26/09/18.
//  Copyright © 2018 Meridian Inc. All rights reserved.
//

import PagedArray
import Foundation
import Alamofire

class GenresMediaComponent {
    var array = PagedArray<Genre>(count: 0, pageSize: 0)
    var currentRequest: DataRequest?
    
    private lazy var pagesLoading = [Int]()
    
    func load(collectionView: UICollectionView?) {
        GenresClient.shared.all(success: { genres in
            guard let count = genres?.count, count > 0, let genres = genres else { // no pagination for now
                return
            }
            
            self.array = PagedArray<Genre>(count: count, pageSize: 10)
            self.array.set(genres, forPage: 0)
            
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
        
        //currentRequest?.cancel()
        //currentRequest = nil
        /*currentRequest = */GenresClient.shared.all(success: { genres in
            self.currentRequest = nil
            self.pagesLoading.removeAll(where: { $0 == currentPage })
            
            guard let genres = genres else {
                return
            }
            
            self.array.set(genres, forPage: currentPage)
            
            collectionView.reloadData()
        }, failure: { error in
            self.currentRequest = nil
            self.pagesLoading.removeAll(where: { $0 == currentPage })
            
            print("GenresMediaComponent Error - \(error.localizedDescription)")
        })
    }
}
