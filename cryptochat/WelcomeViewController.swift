//
//  WelcomeViewController.swift
//  cryptochat
//
//  Created by David Zorychta on 2/24/16.
//  Copyright © 2016 David Zorychta. All rights reserved.
//

import UIKit
import Heimdall
import Security
import CommonCrypto

class WelcomeViewController: BaseViewController
{
    @IBOutlet var input: UITextField!
    @IBOutlet var userIdContainer: UILabel!
    @IBOutlet var welcomeHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    var defaultBottomConstraint : CGFloat = 0.0
    var defaultWelcomeHeightConstraint : CGFloat = 0.0
    var spinner : UIActivityIndicatorView = UIActivityIndicatorView()
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
            
            userIdContainer.text = publicKeyString
        }
        defaultBottomConstraint = self.bottomConstraint.constant
        defaultWelcomeHeightConstraint = self.welcomeHeightConstraint.constant
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ConversationViewController.keyboardWillShow(_:)), name:UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ConversationViewController.keyboardWillHide(_:)), name:UIKeyboardWillHideNotification, object: nil)
        input.addSubview(spinner)
        spinner.activityIndicatorViewStyle = .Gray
        spinner.startAnimating()
        let views = [ "spinner": spinner ]
        spinner.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:[spinner]-|", options: [], metrics: nil, views: views))
        NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-[spinner]-|", options: [], metrics: nil, views: views))
        view.addConstraint(NSLayoutConstraint(item: spinner, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: spinner, attribute: NSLayoutAttribute.Width, multiplier: 1, constant: 0))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
  @IBAction func unwindToThisViewController(segue: UIStoryboardSegue) {
    }

    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
            self.bottomConstraint.constant = keyboardSize.height + defaultBottomConstraint
            self.welcomeHeightConstraint.constant = defaultWelcomeHeightConstraint / 2.0
            UIView.animateWithDuration(0.5) {
                self.view.layoutIfNeeded()
            }
        }
    }

    func keyboardWillHide(notification: NSNotification) {
        self.bottomConstraint.constant = defaultBottomConstraint
        self.welcomeHeightConstraint.constant = defaultWelcomeHeightConstraint
        UIView.animateWithDuration(0.5) {
            self.view.layoutIfNeeded()
        }
    }

}
