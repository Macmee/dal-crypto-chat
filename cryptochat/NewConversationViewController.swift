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
        toUserTextField.autocorrectionType = .No

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func close(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func scanQRAction(sender: AnyObject) {
        if UIImagePickerController.isSourceTypeAvailable(.Camera){
            let readerVC = QRCodeReaderViewController(metadataObjectTypes: [AVMetadataObjectTypeQRCode])
            // Retrieve the QRCode content
            // By using the delegate pattern
            readerVC.delegate = self
            
            // Or by using the closure pattern
            readerVC.completionBlock = { (result: QRCodeReaderResult?) in
                if result != nil {
                    DataFetcher.sharedInstance.getUser((result?.value)!) {
                        user in
                        // set the result from the QR code to the destination textfield
                        self.toUserTextField.text! = user.username
                    }
                }
            }
            // Presents the readerVC as modal form sheet
            readerVC.modalPresentationStyle = .FormSheet
            presentViewController(readerVC, animated: true, completion: nil)
        }
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

extension NewConversationViewController: QRCodeReaderViewControllerDelegate {
    func reader(reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    func readerDidCancel(reader: QRCodeReaderViewController) {
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }
}
