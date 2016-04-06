//  The MessageManager interface with the Message object
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
    // Create a singleton
    public static let sharedInstance = MessageManager()
    // Retrieve all message from the data server and store them locally
    public func downloadAndStoreMessages(complete:()->Void) {
        // retrieve any new message
        DataFetcher.sharedInstance.getMessages { (success, messages) in
            if success {
                for message in messages {
                    // store all the messages
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

    // encrypt the message
    public func encrypt(otherUser : User, message : String) -> String {
        var signature = ""
        // get the signature
        if let heimdall = Heimdall(tagPrefix: DataManager.sharedInstance.getNamespace()) {
            signature = heimdall.sign(message) ?? ""
        }
        // encrypt it
        if let partnerHeimdall = Heimdall(publicTag: DataManager.sharedInstance.getNamespace(), publicKeyData: public_key_data(otherUser.public_key) ) {
            // add the signature and the encrypted message
            return signature.base64Encoded() + "@" + partnerHeimdall.encrypt(message)!.base64Encoded()
        }
        return ""
    }

    // decrypt the message
    public func decrypt(public_key : String, message : String) -> String {
        // get the namespace
        let localHeimdall = Heimdall(tagPrefix: DataManager.sharedInstance.getNamespace())
        if let heimdall = localHeimdall {
            // break it up
            let parts = message.componentsSeparatedByString("@")
            if parts.count < 2 {
                return "[MALFORMED]"
            }
            // get the signature
            let signature = parts[0].base64Decoded()
            // get the encrypted message
            let encryptedMessage = parts[1].base64Decoded()
            // decrypt the message
            if let decryptedMessage = heimdall.decrypt(encryptedMessage) {
                let decrypted = decryptedMessage
                // check
                let verified = heimdall.verify(decrypted, signatureBase64: signature)
                // check if img and return
                if !verified && !decrypted.hasPrefix("IMG:") {
                    return decrypted
                }
                // return
                return decrypted
            }
        }
        return message
    }

}