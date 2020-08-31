//
//  BeatsMediaComponent.swift
//  RecordGram
//
//  Created by Hugo Prione on 26/09/18.
//  Copyright © 2018 Meridian Inc. All rights reserved.
//

import UIKit
import PagedArray
import Alamofire

class BeatsMediaComponent {
    var array = PagedArray<Beat>(count: 0, pageSize: 0)
    var currentRequest: DataRequest?
    
    private lazy var pagesLoading = [Int]()
    
    func load(tableView: UITableView) {
        BeatsClient.shared.get(page: 1, success: { beats, total, limit in
            guard let count = total, count > 0, let beats = beats else {
                return
            }
            
            self.array = PagedArray<Beat>(count: count, pageSize: limit)
            self.array.set(beats, forPage: 0)
            
            tableView.reloadData()
            tableView.backgroundColor = UIColor.white
        }, failure: { _ in })
    }
    
    // TODO: 2018-09-26 refactor dry
    func load(genre: Genre, tableView: UITableView) {
        guard let uuid = genre.uuid else {
            return
        }
        BeatsClient.shared.get(genre: uuid, page: 1, success: { beats, total, limit in
            guard let count = total, count > 0, let beats = beats else {
                return
            }
            
            self.array = PagedArray<Beat>(count: count, pageSize: limit)
            self.array.set(beats, forPage: 0)
            
            tableView.reloadData()
            tableView.backgroundColor = UIColor.white
        }, failure: { _ in })
    }
    
    func loadDataIfNeeded(for indexPath: IndexPath, on tableView: UITableView) {
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
        currentRequest = BeatsClient.shared.get(page: currentPage + 1, success: { feed, _, _ in
            self.currentRequest = nil
            self.pagesLoading.removeAll(where: { $0 == currentPage })
            
            guard let feed = feed else {
                return
            }
            
            self.array.set(feed, forPage: currentPage)
            
            tableView.reloadData()
        }, failure: { error in
            self.currentRequest = nil
            self.pagesLoading.removeAll(where: { $0 == currentPage })
            
            print("BeatsMediaComponent Error - \(error.localizedDescription)")
        })
    }
    
    // TODO: 2018-09-26 refactor dry
    func loadDataIfNeeded(genre: Genre, for indexPath: IndexPath, on tableView: UITableView) {
        guard let uuid = genre.uuid else {
            return
        }
        
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
        currentRequest = BeatsClient.shared.get(genre: uuid, page: currentPage + 1, success: { feed, _, _ in
            self.currentRequest = nil
            self.pagesLoading.removeAll(where: { $0 == currentPage })
            
            guard let feed = feed else {
                return
            }
            
            self.array.set(feed, forPage: currentPage)
            
            tableView.reloadData()
        }, failure: { error in
            self.currentRequest = nil
            self.pagesLoading.removeAll(where: { $0 == currentPage })
            
            print("BeatsMediaComponent Error - \(error.localizedDescription)")
        })
    }
}
