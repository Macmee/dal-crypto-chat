//
//  MessageManager.swift
//  cryptochat
//
//  Created by David Zorychta on 2016-03-28.
//  Copyright © 2016 David Zorychta. All rights reserved.
//

import Foundation
import UIKit
import Heimdall

public class MessageManager {

    public static let sharedInstance = MessageManager()

    public func downloadAndStoreMessages(complete:()->Void) {
        DataFetcher.sharedInstance.getMessages { (success, messages) in
            if success {
                for message in messages {
                    DataManager.sharedInstance.storeMessage(message)
                }
            }
            complete()
        }
    }

    public func public_key_data(public_key : String) -> NSData {
        var key = public_key
        key = key.stringByReplacingOccurrencesOfString("_", withString: "/")
        key = key.stringByReplacingOccurrencesOfString("-", withString: "+")
        return NSData(base64EncodedString: key, options:NSDataBase64DecodingOptions(rawValue: 0))!
    }

    public func encrypt(otherUser : User, message : String) -> String {
        var signature = ""
        if let heimdall = Heimdall(tagPrefix: DataManager.sharedInstance.getNamespace()) {
            signature = heimdall.sign(message) ?? ""
        }
        if let partnerHeimdall = Heimdall(publicTag: DataManager.sharedInstance.getNamespace(), publicKeyData: Heimdall(tagPrefix: DataManager.sharedInstance.getNamespace())!.publicKeyDataX509() ) {
            return /*signature + "\n" + */partnerHeimdall.encrypt(message)!
        }
        return ""
    }

    public func decrypt(public_key : String, message : String) -> String {
        let localHeimdall = Heimdall(tagPrefix: DataManager.sharedInstance.getNamespace())
        if let heimdall = localHeimdall {
            /*let parts = message.componentsSeparatedByString("\n")
            if parts.count < 2 { return message }*/
            if let decryptedMessage = heimdall.decrypt(/*parts[1]*/message) {
                return decryptedMessage
            }
        }
        return message
    }

}