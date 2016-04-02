//
//  NewConversationViewController.swift
//  cryptochat
//
//  Created by Ario K on 2016-03-10.
//  Copyright © 2016 David Zorychta. All rights reserved.
//

import UIKit

protocol NewConversationDelegate {
    func backFromNewMessage(user: User)
}

class NewConversationViewController: UIViewController {
    
    @IBOutlet weak var toUserTextField: UITextField!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageTextField: UITextField!
    var otherUser: User?
    var delegate: NewConversationDelegate! = nil
    @IBOutlet weak var sendButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.navigationItem.title = "New Message"
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(NewConversationViewController.keyboardWillShow(_:)), name:UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(NewConversationViewController.keyboardWillHide(_:)), name:UIKeyboardWillHideNotification, object: nil)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func close(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func sendButton(sender: AnyObject) {
        let selfUser = DataManager.sharedInstance.getSelfUser()
        DataFetcher.sharedInstance.getUserByName(self.toUserTextField.text!) {
            user in
            if user.exists {
                self.otherUser = user
                let message = MessageManager.sharedInstance.encrypt(self.otherUser!, message: self.messageTextField.text!)
                let m = Message(sender: selfUser!.public_key, receiver: self.otherUser!.public_key, msg: message, id: DataManager.sharedInstance.randomStringWithLength(40), time: NSDate().formattedISO8601)
                DataFetcher.sharedInstance.sendMessage(self.otherUser!.public_key, message: message, completion: { (success) in
                    //                self.downloadAndReloadConversations()
                })
                m.msg = self.messageTextField.text!
                DataManager.sharedInstance.storeMessage(m)
                self.messageTextField.text = ""
                self.dismissViewControllerAnimated(true, completion: {
                    self.delegate!.backFromNewMessage(user)
                })
            }
        }
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
            self.bottomConstraint.constant = -keyboardSize.height
            UIView.animateWithDuration(0.5) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        self.bottomConstraint.constant = 0
        UIView.animateWithDuration(0.5) {
            self.view.layoutIfNeeded()
        }
    }
}
