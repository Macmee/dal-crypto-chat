//  Initialise required data once the user have inputted valid feilds in the WelcomeViewController
//  RegisterViewController.swift
//  cryptochat
//
//  Created by David Zorychta on 2016-03-27.
//  Copyright © 2016 David Zorychta. All rights reserved.
//

import Foundation
import UIKit
import Heimdall
import Security
import CommonCrypto

class RegisterViewController: BaseViewController {
    // inputted username
    var username : String?

    override func viewDidLoad() {
        super.viewDidLoad()
        // The encryption object
        let localHeimdall = Heimdall(tagPrefix: DataManager.sharedInstance.getNamespace())
        if let heimdall = localHeimdall, publicKeyData = heimdall.publicKeyDataX509() {
            // create a Base-64 encoded NSString from the receiver's contents using the given options.
            var publicKeyString = publicKeyData.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
            // a new string in which all occurrences of a target string in a specified range of the String are replaced by another given string.
            publicKeyString = publicKeyString.stringByReplacingOccurrencesOfString("/", withString: "_")
            publicKeyString = publicKeyString.stringByReplacingOccurrencesOfString("+", withString: "-")
            if let username = username {
                // register the user with the server
                DataFetcher.sharedInstance.register(username, public_key: publicKeyString) { success in
                    if !success {
                        self.error("failed registering!", segue: "registerFailed")
                        return
                    }
                    // create a new user object
                    let user = User()
                    // set known user fields
                    user.username = username
                    user.public_key = publicKeyString
                    // create local fields in the data manager, store the user
                    DataManager.sharedInstance.storeUser(user)
                    // configure the settings
                    DataManager.sharedInstance.setSetting("self_id", value: publicKeyString)
                    // send an initial message
                    DataFetcher.sharedInstance.sendMessage(publicKeyString, message: "Hi me!", completion: { (success) in
                        // segue out of the register view controller to the inbox view controller
                        self.performSegueWithIdentifier("registered", sender: self)
                    })
                }
            }
        }
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
