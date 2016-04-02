//
//  ConversationViewController.swift
//  cryptochat
//
//  Created by Ario K on 2016-03-11.
//  Copyright © 2016 David Zorychta. All rights reserved.
//

import UIKit
import MobileCoreServices
import Foundation
import PromiseKit

class ConversationViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    var user: User?
    
    @IBOutlet weak var tableMessages: UITableView!
    @IBOutlet weak var userTextField: UITextField!
    var messages = [Message]()
    var refreshTimer = NSTimer()
    var latestMessageTime : String?
    var imagePicker: UIImagePickerController!
    var locationResolver : LocationManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableMessages.alpha = 0
        UIView.animateWithDuration(2.0) {
            self.tableMessages.alpha = 1
        }
        tableMessages.dataSource = self
        tableMessages.delegate = self
        tableMessages.separatorStyle = .None
        tableMessages.contentInset = UIEdgeInsetsMake(MessageTableViewCell.cellPadding, 0.0, 0.0, 0.0)
        self.navigationItem.title = user?.username
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                selector: #selector(ConversationViewController.keyboardWillShow(_:)),
                                                         name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                selector: #selector(ConversationViewController.keyboardWillHide(_:)),
                                                         name: UIKeyboardWillHideNotification, object: nil)
        reloadConversations()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        refreshTimer.invalidate()
    }
    
    func tableViewScrollToBottom(animated: Bool) {
        let numberOfSections = self.tableMessages.numberOfSections
        let numberOfRows = self.tableMessages.numberOfRowsInSection(numberOfSections-1)
        
        if numberOfRows > 0 {
            let indexPath = NSIndexPath(forRow: numberOfRows-1, inSection: (numberOfSections-1))
            self.tableMessages.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Bottom,
                                                      animated: animated)
        }
    }
    
    func reloadConversations() {
        if let user = user {
            self.messages = DataManager.sharedInstance.getMessages(user.public_key)
            let lastSeenMsgTime = latestMessageTime ?? "never"
            let lastGotMsgTime = self.messages.last?.time ?? "now"
            if lastSeenMsgTime != lastGotMsgTime {
                self.tableMessages.reloadData()
                tableViewScrollToBottom(true)
                latestMessageTime = lastGotMsgTime
            }
        }
    }
    
    func downloadAndReloadConversations() {
        if user != nil {
            MessageManager.sharedInstance.downloadAndStoreMessages {
                self.reloadConversations()
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        refreshTimer.invalidate()
        refreshTimer = NSTimer.scheduledTimerWithTimeInterval(2, target: self,
                                                              selector: #selector(ConversationViewController.downloadAndReloadConversations), userInfo: nil,
                                                              repeats: true)
        tableViewScrollToBottom(true)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        tableViewScrollToBottom(true)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        refreshTimer.invalidate()
    }
    
    @IBAction func userSendButton(sender: AnyObject) {
        if let selfUser = DataManager.sharedInstance.getSelfUser(), let otherUser = user where userTextField.text != "" {
            let message = MessageManager.sharedInstance.encrypt(otherUser, message: userTextField.text!)
            let m = Message(sender: selfUser.public_key, receiver: otherUser.public_key, msg: message,
                            id: DataManager.sharedInstance.randomStringWithLength(40), time: NSDate().formattedISO8601)
            DataFetcher.sharedInstance.sendMessage(otherUser.public_key, message: message, completion: { success in
                self.downloadAndReloadConversations()
            })
            m.msg = userTextField.text!
            DataManager.sharedInstance.storeMessage(m)
            userTextField.text = ""
            reloadConversations()
        }
    }
    
    func userSendImage(image : UIImage) {
        if let selfUser = DataManager.sharedInstance.getSelfUser(), let otherUser = user where userTextField.text == "" {
            ImageCom.sharedInstance.toText(image) { text in
                let imageData = "IMG: " + (text as String)
                let message = MessageManager.sharedInstance.encrypt(otherUser, message: imageData)
                let m = Message(sender: selfUser.public_key, receiver: otherUser.public_key, msg: message,
                                id: DataManager.sharedInstance.randomStringWithLength(40),
                                time: NSDate().formattedISO8601)
                DataFetcher.sharedInstance.sendMessage(otherUser.public_key, message: message, completion: { success in
                    self.downloadAndReloadConversations()
                })
                m.msg = imageData
                DataManager.sharedInstance.storeMessage(m)
                self.reloadConversations()
            }
        }
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
        cell?.setMessage(msg)
        return cell!
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let msg = messages[indexPath.row]
        let bublesize: CGSize
        var ret: CGFloat
        if msg.isImage {
            ret = 150 + 16
        } else {
            bublesize = SpeechBubbleView.sizeForText((msg.decryptedMessage)) as CGSize
            ret = bublesize.height + 16
        }
        return ret
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
            self.bottomConstraint.constant = -keyboardSize.height
            UIView.animateWithDuration(0.5) {
                self.view.layoutIfNeeded()
            }
        }
        tableViewScrollToBottom(true)
    }

    func keyboardWillHide(notification: NSNotification) {
        self.bottomConstraint.constant = 0
        UIView.animateWithDuration(0.5) {
            self.view.layoutIfNeeded()
        }
    }

    // MARK - action sheet logic for "attach" button in bottom left
    
    @IBAction func displayImagePickerActionSheet(sender: AnyObject) {
        let optionOneText = "Share Location"
        let optionTwoText = "Take Photo"
        let optionThreeText = "Choose Photo from Library"
        let optionFourText = "Cancel"
        
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)

        let actionOne = UIAlertAction(title: optionOneText, style: .Default) { (ACTION) in
            print("Share location tapped")
            self.shareLocation()
        }
        let actionTwo = UIAlertAction(title: optionTwoText, style: .Default) { (ACTION) in
            print("Take photo tapped")
            self.choosePhoto(.Camera)
        }
        let actionThree = UIAlertAction(title: optionThreeText, style: .Default) { (ACTION) in
            print("Choose library tapped")
            self.choosePhoto(.PhotoLibrary)
        }
        let actionFour = UIAlertAction(title: optionFourText, style: .Default, handler: nil)
        
        actionSheet.addAction(actionOne)
        actionSheet.addAction(actionTwo)
        actionSheet.addAction(actionThree)
        actionSheet.addAction(actionFour)
        self.presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    func choosePhoto(caseType: UIImagePickerControllerSourceType ) {
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self

        if UIImagePickerController.isSourceTypeAvailable(caseType) {
            imagePicker.sourceType = caseType
        } else {
            imagePicker.sourceType = caseType
        }
        imagePicker.allowsEditing = false
        imagePicker.mediaTypes = UIImagePickerController.availableMediaTypesForSourceType(imagePicker.sourceType)!
        self.presentViewController(imagePicker, animated: true, completion: nil)
    }

    func shareLocation() {
        locationResolver = LocationManager()
        locationResolver?.imagePromise?.then { image in
            self.userSendImage(image)
        }.error { error in
            let alert = UIAlertView()
            alert.title = "Oh no 😢"
            alert.message = "We're really sorry but we couldn't access your GPS"
            alert.addButtonWithTitle("Okay")
            alert.show()
        }
    }

}

extension ConversationViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        self.dismissViewControllerAnimated(true, completion: nil)
        print("user canceled the camera library")
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        let mediaType = info[UIImagePickerControllerMediaType] as! String
        if mediaType == (kUTTypeImage as String) {
            //user picks a photo to send
            if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
                let image = pickedImage.scaleWithNewWidth(300)
                self.userSendImage(image)
            }
        }
        self.dismissViewControllerAnimated(true , completion: nil)
    }
}
