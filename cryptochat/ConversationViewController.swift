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
    var dataManager: DataManager!
    
    @IBOutlet weak var tableMessages: UITableView!
    @IBOutlet weak var userTextField: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableMessages.dataSource = self
        tableMessages.delegate = self
        self.navigationItem.title = nameTitle
        self.dataManager = DataManager.dataManager
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name:UIKeyboardWillShowNotification, object: nil);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name:UIKeyboardWillHideNotification, object: nil);
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self);
    }


    @IBAction func userSendButton(sender: AnyObject) {
        print(userTextField.text)
        let m = Message(sender: self.dataManager.USER_ID, receiver: self.navigationItem.title!, msg: userTextField.text!, id: "1234", time: "1234", isFromUser: true)
        dataManager.storeMessage(m)
        dataManager.getMessages(nameTitle!)
        userTextField.text = ""
        tableMessages.reloadData()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataManager.msgCollection.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let CellIdentifier = "MessageCellIdentifier"
        var cell:MessageTableViewCell? = tableView.dequeueReusableCellWithIdentifier(CellIdentifier) as? MessageTableViewCell
        
        if cell == nil {
            cell = MessageTableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: CellIdentifier)
        }
        cell?.backgroundColor = UIColor.clearColor()
        cell?.textLabel?.textColor = UIColor.whiteColor()
        let msg = dataManager.msgCollection[indexPath.row]
        cell?.setMessage(msg);
        return cell!
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let msg = dataManager.msgCollection[indexPath.row]
        let bublesize = SpeechBubbleView.sizeForText((msg.msg)) as CGSize
        return bublesize.height + 16
    }
    
    func keyboardWillShow(notification: NSNotification) {
        var info = notification.userInfo!
        var keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        print(-(keyboardFrame.size.height + 20))
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            self.bottomConstraint.constant = -(keyboardFrame.size.height)
        })
    }
    
    func keyboardWillHide(notification: NSNotification) {
        var info = notification.userInfo!
        var keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        print(-(keyboardFrame.size.height + 20))
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            self.bottomConstraint.constant = (keyboardFrame.size.height)
        })
    }
    
}
