//
//  ConversationViewController.swift
//  cryptochat
//
//  Created by Ario K on 2016-03-11.
//  Copyright © 2016 David Zorychta. All rights reserved.
//

import UIKit


class ConversationViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    var nameTitle: String?
    
    @IBOutlet weak var tableMessages: UITableView!
    @IBOutlet weak var userTextField: UITextField!
    var messages = [Message]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableMessages.dataSource = self
        tableMessages.delegate = self
        self.navigationItem.title = nameTitle
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ConversationViewController.keyboardWillShow(_:)), name:UIKeyboardWillShowNotification, object: nil);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ConversationViewController.keyboardWillHide(_:)), name:UIKeyboardWillHideNotification, object: nil);
        reloadConversations()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self);
    }

    func reloadConversations() {
        messages = DataManager.sharedInstance.getMessages(nameTitle!)
        tableMessages.reloadData()
    }


    @IBAction func userSendButton(sender: AnyObject) {
        print(userTextField.text)
        let m = Message(sender: DataManager.sharedInstance.USER_ID, receiver: self.navigationItem.title!, msg: userTextField.text!, id: "1234", time: "1234", isFromUser: true)
        DataManager.sharedInstance.storeMessage(m)
        userTextField.text = ""
        reloadConversations()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let CellIdentifier = "MessageCellIdentifier"
        var cell:MessageTableViewCell? = tableView.dequeueReusableCellWithIdentifier(CellIdentifier) as? MessageTableViewCell
        
        if cell == nil {
            cell = MessageTableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: CellIdentifier)
        }
        cell?.backgroundColor = UIColor.clearColor()
        cell?.textLabel?.textColor = UIColor.whiteColor()
        let msg = messages[indexPath.row]
        cell?.setMessage(msg);
        return cell!
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let msg = messages[indexPath.row]
        let bublesize = SpeechBubbleView.sizeForText((msg.msg)) as CGSize
        return bublesize.height + 16
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
