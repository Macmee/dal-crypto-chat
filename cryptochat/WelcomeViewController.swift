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
    @IBOutlet var continueButton: CustomButton!
    @IBOutlet var input: CustomTextField!
    @IBOutlet var userIdContainer: UILabel!
    @IBOutlet var welcomeHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    var defaultBottomConstraint : CGFloat = 0.0
    var defaultWelcomeHeightConstraint : CGFloat = 0.0
    let spinner : UIActivityIndicatorView = UIActivityIndicatorView()
    let check = UIImageView(image: UIImage(named: "check"))
    let x =  UIImageView(image: UIImage(named: "x"))
    var fetchUserDebounce = NSTimer()
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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(WelcomeViewController.keyboardWillShow(_:)), name:UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(WelcomeViewController.keyboardWillHide(_:)), name:UIKeyboardWillHideNotification, object: nil)
        input.addTarget(self, action: #selector(WelcomeViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        spinner.activityIndicatorViewStyle = .Gray
        continueButton.alpha = 0.2
        for view in [check, x, spinner] {
            view.hidden = true
            input.addSubview(view)
            view.translatesAutoresizingMaskIntoConstraints = false
            let views = [ "view": view ]
            NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:[view]-10-|", options: [], metrics: nil, views: views))
            NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-[view]-|", options: [], metrics: nil, views: views))
            view.addConstraint(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Width, multiplier: 1, constant: 0))
        }
    }

    @objc func handleGetUserResult(timer : NSTimer) {
        let user = (timer.userInfo ?? User()) as! User
        if user.username == (input.text ?? "") {
            self.spinner.hidden = true
            self.spinner.stopAnimating()
            self.check.hidden = user.exists
            self.x.hidden = !user.exists
            self.continueButton.alpha = user.exists ? 0.2 : 1.0
        }
    }

    func textFieldDidChange(textField: UITextField) {
        let inputName = input.text ?? ""
        if inputName == "" {
            spinner.hidden = true
            spinner.stopAnimating()
            check.hidden = true
            x.hidden = true
            continueButton.alpha = 0.2
            return
        }
        spinner.hidden = false
        spinner.startAnimating()
        check.hidden = true
        x.hidden = true
        continueButton.alpha = 0.2
        DataFetcher.sharedInstance.getUser(inputName) { user in
            self.fetchUserDebounce.invalidate()
            self.fetchUserDebounce = NSTimer.scheduledTimerWithTimeInterval(0.25, target: self, selector: #selector(WelcomeViewController.handleGetUserResult(_:)), userInfo: (user as AnyObject), repeats: false)
        }
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
