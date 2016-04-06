//  Message object that holds all the message related data
//  Message.swift
//  cryptochat
//
//  Created by Yuanjiang Lin on 16/3/12.
//  Copyright © 2016年 David Zorychta. All rights reserved.
//

import UIKit

public class Message : NSObject {
    // sender publickey
    var sender : String
    // receiver publickey
    var receiver : String
    // msg that is sent to recieved
    var msg : String
    // unique identifier
    var id : String
    // time sent/recieved
    var time : String
    // boolean to know who it's from
    var isFromUser: Bool {
        get {
            // get it from the datamanager since it's already computed there
            if let myself = DataManager.sharedInstance.getSelfUser() {
                // return it
                return myself.public_key == sender
            } else {
                return false
            }
        }
    }
    // check if the msg is an image
    var isImage: Bool {
        get {
            // images have the follow prefix:
            return decryptedMessage.hasPrefix("IMG: ")
        }
    }
    // remove the prefix from the image so we just have the image string
    var imageString: String {
        get {
            let index = decryptedMessage.startIndex.advancedBy(5)
            return decryptedMessage.substringFromIndex(index)
        }
    }
    // decrypt the message
    var _decryptedMessage : String?
    var decryptedMessage: String {
        get {
            if _decryptedMessage == nil {
                // utilize the method in message manager
                _decryptedMessage = MessageManager.sharedInstance.decrypt(sender, message: msg)
                // we failed to decrypt the msg, but it's from ourself, we store messages we SENT *NOT* signed by their pub
                if _decryptedMessage == "[MALFORMED]" && isFromUser {
                    // message is decrypted
                    _decryptedMessage = msg
                }
            }
            return _decryptedMessage!
        }
    }
    // initializers
    init(sender : String, receiver : String, msg : String, id : String, time : String) {
        self.sender = sender
        self.receiver = receiver
        self.msg = msg
        self.id = id
        self.time = time
    }
    
    // we can now find out who the other user is since we know self
    func otherUserId() -> String {
        if let myself = DataManager.sharedInstance.getSelfUser() {
            return myself.public_key == sender ? receiver : sender
        } else {
            return ""
        }
    }
}
