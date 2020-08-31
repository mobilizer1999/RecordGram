//
//  Response.swift
//  RecordGram
//
//  Created by Hugo Prione on 18/09/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import Foundation

struct Response<T> {
    var perPage: Int?
    var currentPage: Int?
    var nextPageUrl: String?
    var prevPageUrl: String?
    var from: Int?
    var to: Int?
    var data: T?
    var status: Bool?
    var httpCode: Int?
    var responseTime: Double?
    var message: String?
}
