//
//  WelcomeViewController.swift
//  cryptochat
//
//  Created by David Zorychta on 2/24/16.
//  Copyright © 2016 David Zorychta. All rights reserved.
//

import UIKit

class WelcomeViewController: BaseViewController, UITextFieldDelegate
{
    @IBOutlet var continueButton: CustomButton!
    @IBOutlet var input: CustomTextField!
    @IBOutlet var userIdContainer: UILabel!
    @IBOutlet var welcomeHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    var defaultBottomConstraint : CGFloat = 0.0
    let transparentButtonAmount : CGFloat = 0.2
    var defaultWelcomeHeightConstraint : CGFloat = 0.0
    let spinner : UIActivityIndicatorView = UIActivityIndicatorView()
    let check = UIImageView(image: UIImage(named: "check"))
    let x =  UIImageView(image: UIImage(named: "x"))
    var fetchUserDebounce = NSTimer()
    override func viewDidLoad() {
        super.viewDidLoad()
        if let user = DataManager.sharedInstance.getSelfUser() {
            performSegueWithIdentifier("registered", sender: self)
            for item in view.subviews {
                item.hidden = true
            }
            return
        }
        defaultBottomConstraint = self.bottomConstraint.constant
        defaultWelcomeHeightConstraint = self.welcomeHeightConstraint.constant
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(WelcomeViewController.keyboardWillShow(_:)), name:UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(WelcomeViewController.keyboardWillHide(_:)), name:UIKeyboardWillHideNotification, object: nil)
        input.delegate = self
        input.addTarget(self, action: #selector(WelcomeViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        spinner.activityIndicatorViewStyle = .Gray
        continueButton.alpha = transparentButtonAmount
        for item in [check, x, spinner] {
            item.hidden = true
            input.addSubview(item)
            item.translatesAutoresizingMaskIntoConstraints = false
            let views = [ "view": item ]
            NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:[view]-10-|", options: [], metrics: nil, views: views))
            NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-[view]-|", options: [], metrics: nil, views: views))
            item.addConstraint(NSLayoutConstraint(item: item, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: item, attribute: NSLayoutAttribute.Width, multiplier: 1, constant: 0))
        }
        continueButton.button.addTarget(self, action: "pressedContinue:", forControlEvents: .TouchUpInside)
    }

    override func viewDidAppear(animated: Bool) {
        if let user = DataManager.sharedInstance.getSelfUser() {
            performSegueWithIdentifier("registered", sender: self)
        }
    }

    @objc func handleGetUserResult(timer : NSTimer) {
        let user = (timer.userInfo ?? User()) as! User
        if user.username == (input.text ?? "") {
            self.spinner.hidden = true
            self.spinner.stopAnimating()
            self.check.hidden = user.exists
            self.x.hidden = !user.exists
            UIView.animateWithDuration(0.5) {
                self.continueButton.alpha = user.exists ? self.transparentButtonAmount : 1.0
            }
        }
    }

    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let aSet = NSCharacterSet(charactersInString:"abcdefghijklmnopqrstuvwxyz0123456789").invertedSet
        let compSepByCharInSet = string.componentsSeparatedByCharactersInSet(aSet)
        let numberFiltered = compSepByCharInSet.joinWithSeparator("")
        return string == numberFiltered
    }

    func textFieldDidChange(textField: UITextField) {
        let inputName = input.text ?? ""
        if inputName == "" {
            spinner.hidden = true
            spinner.stopAnimating()
            check.hidden = true
            x.hidden = true
            continueButton.alpha = transparentButtonAmount
            return
        }
        spinner.hidden = false
        spinner.startAnimating()
        check.hidden = true
        x.hidden = true
        continueButton.alpha = transparentButtonAmount
        DataFetcher.sharedInstance.getUserByName(inputName) { user in
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

    func pressedContinue(sender: UIButton) {
        if continueButton.alpha == 1.0 {
            self.performSegueWithIdentifier("continue", sender: sender)
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        if (segue.identifier == "continue") {
            var registerVC = segue!.destinationViewController as! RegisterViewController
            registerVC.username = input.text ?? ""
            
        }
    }

}
