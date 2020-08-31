//
//  ProducerBeatsMediaComponent.swift
//  RecordGram
//
//  Created by Hugo Prione on 26/09/18.
//  Copyright © 2018 Meridian Inc. All rights reserved.
//

import UIKit
import PagedArray
import Alamofire

class ProducerBeatsMediaComponent {
    var array = PagedArray<Beat>(count: 0, pageSize: 0)
    var currentRequest: DataRequest?
    
    private lazy var pagesLoading = [Int]()
    
    var uuid: String
    
    init(uuid: String) {
        self.uuid = uuid
    }
    
    func load(tableView: UITableView) {
        ProducersClient.shared.beats(uuid: uuid, page: 1, success: { beats, total, limit in
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
        currentRequest = ProducersClient.shared.beats(uuid: uuid, page: currentPage + 1, success: { feed, _, _ in
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
            
            print("ProducerBeatsMediaComponent Error - \(error.localizedDescription)")
        })
    }
}
