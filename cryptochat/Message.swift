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

    var _decryptedMessage : String?
    var decryptedMessage: String {
        get {
            return MessageManager.sharedInstance.decrypt(sender, message: msg)
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
