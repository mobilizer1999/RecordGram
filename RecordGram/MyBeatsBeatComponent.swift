//
// Created by Nicolas Gonzalez on 2/6/18.
// Copyright (c) 2018 Meridian Inc. All rights reserved.
//

import UIKit
import PagedArray
import Alamofire

class BeatComponent {
    static let limit = 11
    
    private var items = PagedArray<Beat>(count: 0, pageSize: 0)
    private var currentRequest: DataRequest?
    
    private lazy var pagesLoading = [Int]()
    
    var function: (_ uuid: String, _ page: Int, _ limit: Int, _ success: @escaping (_ beats: [Beat]?, _ total: Int?) -> Void, _ failure: @escaping (_ error: NSError) -> Void) -> DataRequest

    init(using function: @escaping (_ uuid: String, _ page: Int, _ limit: Int, _ success: @escaping (_ beats: [Beat]?, _ total: Int?) -> Void, _ failure: @escaping (_ error: NSError) -> Void) -> DataRequest) {
        self.function = function
    }
    
    func count() -> Int {
        return items.count
    }
    
    func item(at indexPath: IndexPath) -> Beat? {
        return items[indexPath.row]
    }

    func load(tableView: UITableView) {
        _ = function(UserClient.shared.uuid(), 1, BeatComponent.limit, { feed, total in
            guard let count = total, count > 0, let feed = feed else {
                return
            }
            
            self.items = PagedArray<Beat>(count: count, pageSize: BeatComponent.limit)
            self.items.set(feed, forPage: 0)
            
            tableView.reloadData()
        }, { _ in })
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
        currentRequest = function(UserClient.shared.uuid(), currentPage + 1, BeatComponent.limit, { feed, total in
            self.currentRequest = nil
            self.pagesLoading.removeAll(where: { $0 == currentPage })
            
            guard let feed = feed else {
                return
            }
            
            self.items.set(feed, forPage: currentPage)
            
            tableView.reloadData()
        }, { error in
            self.currentRequest = nil
            self.pagesLoading.removeAll(where: { $0 == currentPage })
            
            print("BeatComponent Error - \(error.localizedDescription)")
        })
    }
}
