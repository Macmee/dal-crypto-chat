//  User object that holds all user related data
//  User.swift
//  cryptochat
//
//  Created by David Zorychta on 2016-03-26.
//  Copyright © 2016 David Zorychta. All rights reserved.
//

import UIKit

public class User : NSObject {
    // check to see if users exist
    var exists : Bool = false
    // username
    var username : String = ""
    // public key of user
    var public_key : String = ""
    // dummy test data
    public static func dummy() -> User {
        let user = User()
        user.exists = true
        user.username = "Stan"
        user.public_key = "1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890"
        return user
    }

}
