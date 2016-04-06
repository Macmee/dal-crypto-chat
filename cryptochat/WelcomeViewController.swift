// The welcome to the application screen where the user can choose a username and
// start using the application
//  WelcomeViewController.swift
//  cryptochat
//
//  Created by David Zorychta on 2/24/16.
//  Copyright © 2016 David Zorychta. All rights reserved.
//

import UIKit

class WelcomeViewController: BaseViewController, UITextFieldDelegate
{
    // continue button after username is inputted
    @IBOutlet var continueButton: CustomButton!
    // the user name input textfield
    @IBOutlet var input: CustomTextField!
    // the label that guides the username text field
    @IBOutlet var userIdContainer: UILabel!
    // height constraint
    @IBOutlet var welcomeHeightConstraint: NSLayoutConstraint!
    // bottom constraint
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    // bottom constraight
    var defaultBottomConstraint : CGFloat = 0.0
    // transparency value
    let transparentButtonAmount : CGFloat = 0.2
    // heigh constraint
    var defaultWelcomeHeightConstraint : CGFloat = 0.0
    // acitivty indicator for checking valid username
    let spinner : UIActivityIndicatorView = UIActivityIndicatorView()
    // spinner validation, correct
    let check = UIImageView(image: UIImage(named: "check"))
    // spinner validation, taken
    let x =  UIImageView(image: UIImage(named: "x"))
    // timer for validation
    var fetchUserDebounce = NSTimer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // getting a public key
        if let user = DataManager.sharedInstance.getSelfUser() {
            // performing the segue if already registered
            performSegueWithIdentifier("registered", sender: self)
            // hide everything
            for item in view.subviews {
                item.hidden = true
            }
            return
        }
        // set the bottom constraint
        defaultBottomConstraint = self.bottomConstraint.constant
        // set the height constraint
        defaultWelcomeHeightConstraint = self.welcomeHeightConstraint.constant
        // keyboard event listeners, show
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(WelcomeViewController.keyboardWillShow(_:)), name:UIKeyboardWillShowNotification, object: nil)
        //keyboard even listeners, hide
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(WelcomeViewController.keyboardWillHide(_:)), name:UIKeyboardWillHideNotification, object: nil)
        // delegate to check for inputs
        input.delegate = self
        //input event listener to check for editing
        input.addTarget(self, action: #selector(WelcomeViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        // spinner color
        spinner.activityIndicatorViewStyle = .Gray
        // continue button transparency
        continueButton.alpha = transparentButtonAmount
        //
        for item in [check, x, spinner] {
            item.hidden = true
            input.addSubview(item)
            item.translatesAutoresizingMaskIntoConstraints = false
            let views = [ "view": item ]
            NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:[view]-10-|", options: [], metrics: nil, views: views))
            NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-[view]-|", options: [], metrics: nil, views: views))
            item.addConstraint(NSLayoutConstraint(item: item, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: item, attribute: NSLayoutAttribute.Width, multiplier: 1, constant: 0))
        }
        // even listener for continue button
        continueButton.button.addTarget(self, action: "pressedContinue:", forControlEvents: .TouchUpInside)
    }

    override func viewDidAppear(animated: Bool) {
        // check if we have already registered when view appears and perform segue instantly
        if let user = DataManager.sharedInstance.getSelfUser() {
            performSegueWithIdentifier("registered", sender: self)
        }
    }
    // Modify spinner to show if user name is valid/invalid using spinner
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
    
    //
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let aSet = NSCharacterSet(charactersInString:"abcdefghijklmnopqrstuvwxyz0123456789").invertedSet
        let compSepByCharInSet = string.componentsSeparatedByCharactersInSet(aSet)
        let numberFiltered = compSepByCharInSet.joinWithSeparator("")
        return string == numberFiltered
    }

    // Perform spinner changes when text field changes
    func textFieldDidChange(textField: UITextField) {
        let inputName = input.text ?? ""
        // if no input, don't show the spinner
        if inputName == "" {
            spinner.hidden = true
            // stop the animation
            spinner.stopAnimating()
            // hide everything
            check.hidden = true
            x.hidden = true
            // make the button 'gray'
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
    
    //keyboard show function
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
            self.bottomConstraint.constant = keyboardSize.height + defaultBottomConstraint
            self.welcomeHeightConstraint.constant = defaultWelcomeHeightConstraint / 2.0
            UIView.animateWithDuration(0.5) {
                self.view.layoutIfNeeded()
            }
        }
    }
    // keyboard hide function
    func keyboardWillHide(notification: NSNotification) {
        self.bottomConstraint.constant = defaultBottomConstraint
        self.welcomeHeightConstraint.constant = defaultWelcomeHeightConstraint
        UIView.animateWithDuration(0.5) {
            self.view.layoutIfNeeded()
        }
    }
    // continue button pressed
    func pressedContinue(sender: UIButton) {
        if continueButton.alpha == 1.0 {
            self.performSegueWithIdentifier("continue", sender: sender)
        }
    }
    // segue on!
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        if (segue.identifier == "continue") {
            var registerVC = segue!.destinationViewController as! RegisterViewController
            registerVC.username = input.text ?? ""
            
        }
    }

}
