//  This view is used to initiate a conversation with another application user
//  The user can add another user by their username or by scanning a QR Code.
//
//  NewConversationViewController.swift
//  cryptochat
//
//  Created by Ario K on 2016-03-10.
//  Copyright © 2016 David Zorychta. All rights reserved.
//

import UIKit
import QRCodeReader
import AVFoundation

// A delegate protocol to send user information back to the inbox controller
// such that the proper conversation view controller can retrieve the right
// message data from the database
protocol NewConversationDelegate {
    func backFromNewMessage(user: User)
}

class NewConversationViewController: UIViewController {
    // The textfield where sender username is inputted
    @IBOutlet weak var toUserTextField: UITextField!
    // the bottom contraint of the superview needed for on-screen keyboard
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    // the message in text format that is to be sent to the sender
    @IBOutlet weak var messageTextField: UITextField!
    // the other users object
    var otherUser: User?
    // delegate to manage sending information back to the inbox view upon completion
    var delegate: NewConversationDelegate! = nil
    // send button to perform the transfer
    @IBOutlet weak var sendButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // set the navigation controllers title
        self.navigationItem.title = "New Message"
        // keyboard show event listener
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(NewConversationViewController.keyboardWillShow(_:)), name:UIKeyboardWillShowNotification, object: nil)
        // keyboard hide event listener
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(NewConversationViewController.keyboardWillHide(_:)), name:UIKeyboardWillHideNotification, object: nil)
        // disable autocorrect since username textfield do not need autocorrect
        toUserTextField.autocorrectionType = .No

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Close the new message view once the "X" icon is tapped
    @IBAction func close(sender: AnyObject) {
        // dismiss the view
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // Action for when 'Scan QR' right navigation controller button is tapped
    @IBAction func scanQRAction(sender: AnyObject) {
        // Check the phone or simulator has a camera source
        if UIImagePickerController.isSourceTypeAvailable(.Camera){
            // initilize to scan a QR code
            let readerVC = QRCodeReaderViewController(metadataObjectTypes: [AVMetadataObjectTypeQRCode])
            // Retrieve the QRCode content
            // By using the delegate pattern
            readerVC.delegate = self
            // Or by using the closure pattern
            readerVC.completionBlock = { (result: QRCodeReaderResult?) in
                // this will be nil if they cancel the view, so do nothing
                if result != nil {
                    // get the public key value from the QR code
                    let public_key = (result?.value)!
                    // Get the user object from the public key
                    UserManager.sharedInstance.getUser(public_key) { user in
                        // set the result from the QR code to the destination textfield
                        self.toUserTextField.text! = user.username + (public_key != user.public_key ? " [UNVERIFIED]" : "")
                    }
                }
            }
            // Presents the readerVC as modal form sheet
            readerVC.modalPresentationStyle = .FormSheet
            // perform the animation
            presentViewController(readerVC, animated: true, completion: nil)
        }
    }
    
    // Action for when the user sends a text message
    @IBAction func sendButton(sender: AnyObject) {
        let selfUser = DataManager.sharedInstance.getSelfUser()
        // note: if we got here from the QR flow, the user will already be in the database so it is SAFE to fetch
        // by name - if the server returned another user with a DIFFERENT public_key then we already alerted
        // our user by adding [UNVERIFIED] to the end of the username (see above QR logic)
        UserManager.sharedInstance.getUserByName(self.toUserTextField.text!) { user in
            // Check if the inputted username exists
            if user.exists {
                // set as the other user
                self.otherUser = user
                // encrypt the inputted message
                let message = MessageManager.sharedInstance.encrypt(self.otherUser!, message: self.messageTextField.text!)
                // wrap the inputted message in the Message datastructure
                let m = Message(sender: selfUser!.public_key, receiver: self.otherUser!.public_key, msg: message, id: DataManager.sharedInstance.randomStringWithLength(40), time: NSDate().formattedISO8601)
                // send the message to the server to the otherUser can retrieve it
                DataFetcher.sharedInstance.sendMessage(self.otherUser!.public_key, message: message, completion: { (success) in
                    self.dismissViewControllerAnimated(true, completion: {
                        // delegate the message to the inbox view controller so that the right ConversationVew can open with all the data
                        self.delegate!.backFromNewMessage(user)
                    })
                })
                // set the message unencrypted
                m.msg = self.messageTextField.text!
                // store in the SQLite db
                DataManager.sharedInstance.storeMessage(m)
                // reset the text field
                self.messageTextField.text = ""
            } else {
                // present a alert view because we did not find the right username
                let alert = UIAlertView()
                // Alert the user what happened
                alert.title = "Oh no 😢"
                alert.message = "We're really sorry but no user exists with that username!"
                // allow them to confirm
                alert.addButtonWithTitle("Okay")
                // show the message
                alert.show()
            }
        }
    }
    
    // show keyboard function
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
            // set the superview contraint so that it does not overlap the view
            self.bottomConstraint.constant = -keyboardSize.height
            UIView.animateWithDuration(0.5) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    // hide the keybaord
    func keyboardWillHide(notification: NSNotification) {
        // reset the contraint
        self.bottomConstraint.constant = 0
        // do an animation
        UIView.animateWithDuration(0.5) {
            // lays out the subviews immediately
            self.view.layoutIfNeeded()
        }
    }
}

// QRCodeReader delegates for when the user opens and closes the QRReader View. 
extension NewConversationViewController: QRCodeReaderViewControllerDelegate {
    func reader(reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    func readerDidCancel(reader: QRCodeReaderViewController) {
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }
}
