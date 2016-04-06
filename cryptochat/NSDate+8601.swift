//  This is a help class for date formatting
//  NSDate+8601.swift
//  cryptochat
//
//  Created by David Zorychta on 2016-03-28.
//  Copyright © 2016 David Zorychta. All rights reserved.
//

import Foundation

extension NSDate {
    struct Date {
        static let formatterISO8601: NSDateFormatter = {
            // create a data object
            let formatter = NSDateFormatter()
            //formate it
            formatter.calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierISO8601)
            // set the locale
            formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
            // set the timezone
            formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
            // set the format
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSX"
            //return
            return formatter
        }()
    }
    var formattedISO8601: String { return Date.formatterISO8601.stringFromDate(self) }
}