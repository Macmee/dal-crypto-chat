//
//  UserManager.swift
//  cryptochat
//
//  Created by David Zorychta on 2016-03-28.
//  Copyright © 2016 David Zorychta. All rights reserved.
//

import Foundation
import UIKit

public class UserManager {

    public static let sharedInstance = UserManager()

    func getUser(public_key:String, complete:(user:User)->Void) {
        let user = DataManager.sharedInstance.getUser(public_key)
        if let user = user {
            complete(user: user)
            return
        }
        DataFetcher.sharedInstance.getUser(public_key) { user in
            DataManager.sharedInstance.storeUser(user)
            complete(user: user)
        }
    }

}