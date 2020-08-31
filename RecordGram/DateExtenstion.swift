//
//  DateExtenstion.swift
//  RecordGram
//
//  Created by Nicolas Gonzalez on 12/30/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import Foundation

extension Date {
    var timeAgo: String {
        let components = Calendar.current.dateComponents(
                [.minute, .hour, .day, .weekOfYear, .month, .year, .second],
                from: self, to: Date())
        let year = components.year ?? 0
        let month = components.month ?? 0
        let weekOfYear = components.weekOfYear ?? 0
        let day = components.day ?? 0
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        let second = components.second ?? 0

        if (year >= 2) {
            return String(format: NSLocalizedString("%d years ago", comment: "Relative date"), year)
        } else if (year >= 1) {
            return NSLocalizedString("1 year ago", comment: "Relative date")
        } else if (month >= 2) {
            return String(format: NSLocalizedString("%d months ago", comment: "Relative date"), month)
        } else if (month >= 1) {
            return NSLocalizedString("1 month ago", comment: "Relative date")
        } else if (weekOfYear >= 2) {
            return String(format: NSLocalizedString("%d weeks ago", comment: "Relative date"), weekOfYear)
        } else if (weekOfYear >= 1) {
            return NSLocalizedString("1 week ago", comment: "Relative date")
        } else if (day >= 2) {
            return String(format: NSLocalizedString("%d days ago", comment: "Relative date"), day)
        } else if (day >= 1) {
            return NSLocalizedString("1 day ago", comment: "Relative date")
        } else if (hour >= 2) {
            return String(format: NSLocalizedString("%d hours ago", comment: "Relative date"), hour)
        } else if (hour >= 1) {
            return NSLocalizedString("1 hour ago", comment: "Relative date")
        } else if (minute >= 2) {
            return String(format: NSLocalizedString("%d mins ago", comment: "Relative date"), minute)
        } else if (minute >= 1) {
            return NSLocalizedString("1 min ago", comment: "Relative date")
        } else if (second >= 3) {
            return String(format: NSLocalizedString("%d secs ago", comment: "Relative date"), second)
        } else {
            return NSLocalizedString("Just now", comment: "Relative date")
        }
    }
}
