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
    var isFromUser: Bool

    init(sender : String, receiver : String, msg : String, id : String, time : String, isFromUser : Bool) {
        self.sender = sender
        self.receiver = receiver
        self.msg = msg
        self.id = id
        self.time = time
        self.isFromUser = isFromUser
    }

    func otherUserId() -> String {
        let myself = DataManager.sharedInstance.getSelfUser()
        if let myself = myself {
            return myself.public_key == sender ? receiver : sender
        } else {
            return ""
        }
    }
}
