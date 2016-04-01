//
//  Message.swift
//  cryptochat
//
//  Created by Yuanjiang Lin on 16/3/12.
//  Copyright © 2016年 David Zorychta. All rights reserved.
//

import UIKit

public class Message : NSObject {
    var sender : String
    var receiver : String
    var msg : String
    var id : String
    var time : String
    var isFromUser: Bool {
        get {
            if let myself = DataManager.sharedInstance.getSelfUser() {
                return myself.public_key == sender
            } else {
                return false
            }
        }
    }
    var isImage: Bool {
        get {
            return decryptedMessage.hasPrefix("IMG: ")
        }
    }

    var _decryptedMessage : String?
    var decryptedMessage: String {
        get {
            if _decryptedMessage == nil {
                _decryptedMessage = MessageManager.sharedInstance.decrypt(sender, message: msg)
                // we failed to decrypt the msg, but it's from ourself, we store messages we SENT *NOT* signed by their pub
                if _decryptedMessage == "[MALFORMED]" && isFromUser {
                    _decryptedMessage = msg
                }
            }
            return _decryptedMessage!
        }
    }

    init(sender : String, receiver : String, msg : String, id : String, time : String) {
        self.sender = sender
        self.receiver = receiver
        self.msg = msg
        self.id = id
        self.time = time
    }

    func otherUserId() -> String {
        if let myself = DataManager.sharedInstance.getSelfUser() {
            return myself.public_key == sender ? receiver : sender
        } else {
            return ""
        }
    }
}
