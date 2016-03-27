//
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

    var username : String?

    override func viewDidLoad() {
        super.viewDidLoad()
        let localHeimdall = Heimdall(tagPrefix: "com.example")
        if let heimdall = localHeimdall, publicKeyData = heimdall.publicKeyDataX509() {

            var publicKeyString = publicKeyData.base64EncodedStringWithOptions(NSDataBase64EncodingOptions())

            // If you want to make this string URL safe,
            // you have to remember to do the reverse on the other side later
            publicKeyString = publicKeyString.stringByReplacingOccurrencesOfString("/", withString: "_")
            publicKeyString = publicKeyString.stringByReplacingOccurrencesOfString("+", withString: "-")

            print(publicKeyString) // Something along the lines of "MIGfMA0GCSqGSIb3DQEBAQUAA..."
            if let username = username {
                DataFetcher.sharedInstance.register(username, public_key: publicKeyString) { success in
                    if !success {
                        self.error("failed registering!", segue: "registerFailed")
                        return
                    }
                    let user = User()
                    user.username = username
                    user.public_key = publicKeyString
                    user.is_self = true
                    DataManager.sharedInstance.storeUser(user)
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
