// This is the converstaion view where the message sender and reciever can interface.
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
    // To set the bottom constraint for when the keyboard opens and closes
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    // the table that stores the messages passed in the conversation
    @IBOutlet weak var tableMessages: UITableView!
    // textfield for sending messages
    @IBOutlet weak var userTextField: UITextField!
    // User object that stores user information
    var user: User?
    // message object which stores message information
    var messages = [Message]()
    // ability to re-render the message view for new messages based on a timer
    var refreshTimer = NSTimer()
    // variable to check for a new incoming message
    var latestMessageTime : String?
    // variable for picking photos from the iphone library
    var imagePicker: UIImagePickerController!
    // geo location object for sharing locations
    var locationResolver : LocationManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // animate table in
        tableMessages.alpha = 0
        UIView.animateWithDuration(2.0) {
            self.tableMessages.alpha = 1
        }

        // set this controller as the data source and delegate for our table
        tableMessages.dataSource = self
        tableMessages.delegate = self
        tableMessages.separatorStyle = .None
        tableMessages.contentInset = UIEdgeInsetsMake(MessageTableViewCell.cellPadding, 0.0, 0.0, 0.0)
        // set the navigation title in the client to who it is having a conversation with
        self.navigationItem.title = user?.username
        // event listener for when the on-screen keyboard opens and closes
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(ConversationViewController.keyboardWillShow(_:)),
                                                         name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(ConversationViewController.keyboardWillHide(_:)),
                                                         name: UIKeyboardWillHideNotification, object: nil)
        // call reload to re-render the conversation list
        reloadConversations()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        refreshTimer.invalidate()
    }
    
    // position to the bottom of the tableview cell
    func tableViewScrollToBottom(animated: Bool) {
        let numberOfSections = self.tableMessages.numberOfSections
        let numberOfRows = self.tableMessages.numberOfRowsInSection(numberOfSections-1)
        
        if numberOfRows > 0 {
            let indexPath = NSIndexPath(forRow: numberOfRows-1, inSection: (numberOfSections-1))
            self.tableMessages.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Bottom,
                                                      animated: animated)
        }
    }
    
    // Query the local SQLite database and retrieve any new message that has been sent.
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
    // Retrive all new messages from the server and store them locally in the SQLite database
    func downloadAndReloadConversations() {
        if user != nil {
            MessageManager.sharedInstance.downloadAndStoreMessages {
                self.reloadConversations()
            }
        }
    }
    
    // Once the conversation view has appeared, do downloadAndReloadConversation() and timer for every x intervals
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

    // Stop the downloading of conversation if we are not in this view anymore
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        refreshTimer.invalidate()
    }
    
    // Action listen button "Send" is pressed for text. We must encrypt and send the message along to the server, localdb and render.
    @IBAction func userSendButton(sender: AnyObject) {
        if let selfUser = DataManager.sharedInstance.getSelfUser(), let otherUser = user where userTextField.text != "" {
            // Encrypt the sent message
            let message = MessageManager.sharedInstance.encrypt(otherUser, message: userTextField.text!)
            // Use the sender and recievers public key to store the message, along with timestamp and a unique id.
            let m = Message(sender: selfUser.public_key, receiver: otherUser.public_key, msg: message,
                            id: DataManager.sharedInstance.randomStringWithLength(40), time: NSDate().formattedISO8601)
            // Send the message off to the server
            DataFetcher.sharedInstance.sendMessage(otherUser.public_key, message: message, completion: { success in
                // once complete check for any incoming messages
                self.downloadAndReloadConversations()
            })
            // set the unencrypted message to save locally
            m.msg = userTextField.text!
            // store the unencrypted message sender sent locally
            DataManager.sharedInstance.storeMessage(m)
            // referes the text field
            userTextField.text = ""
            // reload the conversation view so table view can re-render
            reloadConversations()
        }
    }
    
    // Perform the same action as text with images, however here we need to convert images to string format.
    func userSendImage(image : UIImage) {
        if let selfUser = DataManager.sharedInstance.getSelfUser(), let otherUser = user where userTextField.text == "" {
            // Get the image that is passed and convert to String datastructure
            ImageCom.sharedInstance.toText(image) { text in
                // Attach an identifier to the image so that we can render it as an iamge
                let imageData = "IMG: " + (text as String)
                // Encrypt the sent image
                let message = MessageManager.sharedInstance.encrypt(otherUser, message: imageData)
                // User the sender and recievers public eky to store the message, along with timestamp and unique id.
                let m = Message(sender: selfUser.public_key, receiver: otherUser.public_key, msg: message,
                                id: DataManager.sharedInstance.randomStringWithLength(40),
                                time: NSDate().formattedISO8601)
                // Send the image off to the server
                DataFetcher.sharedInstance.sendMessage(otherUser.public_key, message: message, completion: { success in
                    // once complete, check for any incoming messages
                    self.downloadAndReloadConversations()
                })
                // set the unencrypted string image to save locally
                m.msg = imageData
                // store the image locally
                DataManager.sharedInstance.storeMessage(m)
                // reload the conversation viw such that table view can re-render
                self.reloadConversations()
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // since our array of messages is our data source, there is one cell per message
        return messages.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // this method generates a cell for a given index in the table, first dequeue a recycled cell
        let CellIdentifier = "MessageCellIdentifier"
        var cell:MessageTableViewCell? = tableView.dequeueReusableCellWithIdentifier(CellIdentifier) as? MessageTableViewCell
        
        if cell == nil {
            // a custom message cell so that we can create a visuals and render text/images accordingly
            cell = MessageTableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: CellIdentifier)
        }
        // set some cell properties
        cell?.backgroundColor = UIColor.clearColor()
        cell?.textLabel?.textColor = UIColor.whiteColor()
        // next pull out the Message object from our messages array since its our data source
        let msg = messages[indexPath.row]
        // configure and prepare the cell for rendering
        cell?.setMessage(msg)
        DataManager.sharedInstance.setReadStatus(msg.id, value: true)
        return cell!
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        // pull out the Message object from our messages array since its our data source
        let msg = messages[indexPath.row]
        let bublesize: CGSize
        var ret: CGFloat
        // We need to modify the height of the cell since images are a set size
        if msg.isImage {
            ret = 150 + 16
        } else {
            // size for texts depends on how many words have been sent, so left figure that out
            bublesize = SpeechBubbleView.sizeForText((msg.decryptedMessage)) as CGSize
            ret = bublesize.height + 16
        }
        return ret
    }
    
    // On-screen keyboard properties to push the entire superview up.
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
            self.bottomConstraint.constant = -keyboardSize.height
            UIView.animateWithDuration(0.5) {
                self.view.layoutIfNeeded()
            }
        }
        tableViewScrollToBottom(true)
    }
    
    // On-screen keyboard properties to push the entire superview down.
    func keyboardWillHide(notification: NSNotification) {
        self.bottomConstraint.constant = 0
        UIView.animateWithDuration(0.5) {
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK - action sheet logic for "attach" button in bottom left
    
    @IBAction func displayImagePickerActionSheet(sender: AnyObject) {
        // The list of option avaiable when the user taps the 'attach' button next to the textfield
        let optionOneText = "Share Location"
        let optionTwoText = "Take Photo"
        let optionThreeText = "Choose Photo from Library"
        let optionFourText = "Cancel"
        
        // prepare the object
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        // implement each action
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
        // cancel action
        let actionFour = UIAlertAction(title: optionFourText, style: .Default, handler: nil)
        
        // apply the actions
        actionSheet.addAction(actionOne)
        actionSheet.addAction(actionTwo)
        actionSheet.addAction(actionThree)
        actionSheet.addAction(actionFour)
        
        // display the modal
        self.presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    // We determine which source type has been selected by the user: camera or photo library and delegate the action
    // in order to pop the require source
    func choosePhoto(caseType: UIImagePickerControllerSourceType ) {
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        // check the source based on what is passed from displayImagePickerActionSheet(..)
        if UIImagePickerController.isSourceTypeAvailable(caseType) {
            imagePicker.sourceType = caseType
        } else {
            imagePicker.sourceType = caseType
        }
        imagePicker.allowsEditing = false
        imagePicker.mediaTypes = UIImagePickerController.availableMediaTypesForSourceType(imagePicker.sourceType)!
        self.presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    // If the share location action sheet button is tapped, instantiate the locationManager
    func shareLocation() {
        locationResolver = LocationManager()
        locationResolver?.imagePromise?.then { image in
            // Send the location as and image and perform image operations for sending/saving
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

// Overided photo and camera operations
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
                // Resize the image for quick transfer
                let image = pickedImage.scaleWithNewWidth(300)
                // perform image sending operations
                self.userSendImage(image)
            }
        }
        // terminate once done. 
        self.dismissViewControllerAnimated(true , completion: nil)
    }
}
