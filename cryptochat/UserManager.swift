//  User Manager class that interfaces with User objects
//  UserManager.swift
//  cryptochat
//
//  Created by David Zorychta on 2016-03-28.
//  Copyright © 2016 David Zorychta. All rights reserved.
//

import Foundation
import UIKit

public class UserManager {
    // make this a singleton
    public static let sharedInstance = UserManager()
    // get the user given the public key
    func getUser(public_key:String, complete:(user:User)->Void) {
        let user = DataManager.sharedInstance.getUser(public_key)
        if let user = user {
            complete(user: user)
            return
        }
        // store the user
        DataFetcher.sharedInstance.getUser(public_key) { user in
            DataManager.sharedInstance.storeUser(user)
            complete(user: user)
        }
    }
    // get the user given the username
    func getUserByName(name:String, complete:(user:User)->Void) {
        let user = DataManager.sharedInstance.getUserByName(name)
        if let user = user {
            complete(user: user)
            return
        }
        // store the user give name
        DataFetcher.sharedInstance.getUserByName(name) { user in
            DataManager.sharedInstance.storeUser(user)
            complete(user: user)
        }
    }

}