//  Helper class for encoding to base64 and decoding from base64
//  String+Base64.swift
//  cryptochat
//
//  Created by David Zorychta on 2016-03-29.
//  Copyright © 2016 David Zorychta. All rights reserved.
//

import Foundation

extension String {
    
    // Encode to base64
    func base64Encoded() -> String {
        let plainData = dataUsingEncoding(NSUTF8StringEncoding)
        let base64String = plainData?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
        return base64String!
    }

    // Decode from base64
    func base64Decoded() -> String {
        let decodedData = NSData(base64EncodedString: self, options:NSDataBase64DecodingOptions(rawValue: 0))
        if decodedData == nil {
            return "ERROR"
        }
        let decodedString = String(data: decodedData!, encoding: NSUTF8StringEncoding)
        return decodedString ?? "ERROR"
    }
}