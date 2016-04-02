//
//  ConversationInboxViewController.swift
//  cryptochat
//
//  Created by Ario K on 2016-03-11.
//  Copyright © 2016 David Zorychta. All rights reserved.
//

import UIKit
import Heimdall
import QRCode

class ConversationInboxViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // the table is where we store a list of ongoing conversations
    @IBOutlet weak var tableView: UITableView!

    // the selected user is the user we've tapped on in the table
    var selectedUser : User?

    // an array of message objects, this is the source of content for the table
    var messages = [Message]()

    // polling is used to grab updates every 2 seconds from the server
    var refreshTimer = NSTimer()

    deinit {
        // when this VC is destroyed, stop the refresh timer
        refreshTimer.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // this controller doesnt want the nav bar to be visible
        navigationController?.setNavigationBarHidden(false, animated: true)
        // set this controller as the data source and delegate for our table
        tableView.dataSource = self
        tableView.delegate = self
        // call reload, which will ask the server for new messages and get a list of them for our table
        reloadFromLocalDbOnly()
        reload()
    }

    // MARK - downloading messages from server logic

    // grab messages from the local db and reload the table with those
    func reloadFromLocalDbOnly() {
        self.messages = DataManager.sharedInstance.getConversations()
        self.tableView.reloadData()
    }

    // ask the server for new messages and get a list of them for our table
    func reload() {
        // then ask the server for any new messages, which will be mapped to the db, then reload again
        MessageManager.sharedInstance.downloadAndStoreMessages {
            self.reloadFromLocalDbOnly()
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        // setup the timer to reload messages from the server every 2 seconds
        refreshTimer.invalidate()
        refreshTimer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: #selector(ConversationInboxViewController.reload), userInfo: nil, repeats: true)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func viewWillDisappear(animated: Bool) {
        // when the VC is no longer on screen, stop the refresh timer
        super.viewWillAppear(animated)
        refreshTimer.invalidate()
    }

    // MARK - tableview delegate methods

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // since our array of messages is our data source, there is one cell per message
        return messages.count
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60.0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // this method generates a cell for a given index in the table, first dequeue a recycled cell
        let cell = tableView.dequeueReusableCellWithIdentifier("ConversationCell", forIndexPath: indexPath)
        // next pull out the Message object from our messages array since its our data source
        let message = messages[indexPath.row]
        // fetch the name of the user who sent the message and assign it to the cell's header
        cell.textLabel?.text = "Loading..."
        UserManager.sharedInstance.getUser(message.otherUserId()) { (user) in
            if message.otherUserId() == user.public_key {
                cell.textLabel?.text = user.username
            }
        }
        // if the message is an image just set the cell subheader to "image", otherwise decrypt the message and use that
        cell.detailTextLabel?.text = message.isImage ? "Image" : message.decryptedMessage
        // return our newly constructed cell object for the table to display
        return cell
    }
    
    @IBAction func newMessageSelected(sender: AnyObject) {
        // when the user presses the + button in the top right of the VC, perform NewMessageSegue to show the send
        // message VC
        self.performSegueWithIdentifier("NewMessageSegue", sender: self)
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // find the message object that was selected from the indexPath selected
        let message = messages[indexPath.row]
        // fetch the user object corresponding to whoever send us the message
        UserManager.sharedInstance.getUser(message.otherUserId()) { (user) in
            // keep track of the currently selected user as a state variable
            self.selectedUser = user
            // trigger the segue to switch to the conversation
            self.performSegueWithIdentifier("toConvo", sender: self)
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "toConvo") {
            // toConvo is the segue representing the view for a single conversation, tell the ConversationVC who the
            // selected user is
            let destinationVC = segue.destinationViewController as! ConversationViewController
            destinationVC.user = selectedUser
        }
        if (segue.identifier == "NewMessageSegue") {
            // NewMessageSegue is the segue representing the view for sending a brand new message, assign ourselves as
            // its delegate so that it sends us infomration such as the message and recipient of the message once the
            // user specifies both
            let nav = segue.destinationViewController as! UINavigationController
            let svc = nav.topViewController as! NewConversationViewController
            svc.delegate = self
        }
    }

    @IBAction func displayImagePickerActionSheet(sender: AnyObject) {
        let optionOneText = "Delete Everything"
        let optionTwoText = "Change Servers"
        let optionThreeText = "My QRCode"
        let optionFourText = "Cancel"
        
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)

        let actionOne = UIAlertAction(title: optionOneText, style: .Destructive) { (ACTION) in
            DataManager.sharedInstance.resetDatabase()
            self.performSegueWithIdentifier("toRegistration", sender: self)
        }
        let actionTwo = UIAlertAction(title: optionTwoText, style: .Default) { (ACTION) in
            self.showServerChangePrompt()
        }
        let actionThree = UIAlertAction(title: optionThreeText, style: .Default) { (ACTION) in
            self.showMyQRCodePrompt()
        }
        let actionFour = UIAlertAction(title: optionFourText, style: .Default, handler: nil)

        actionSheet.addAction(actionOne)
        actionSheet.addAction(actionTwo)
        actionSheet.addAction(actionThree)
        actionSheet.addAction(actionFour)
        self.presentViewController(actionSheet, animated: true, completion: nil)
    }

    func showServerChangePrompt() {
        let alert = UIAlertController(title: "Change Server", message: "Enter a new server path without a trailing slash", preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler({ (textField) -> Void in
            textField.text = DataManager.sharedInstance.getSetting("serverPath")!
        })
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
            let textField = alert.textFields![0] as UITextField
            DataManager.sharedInstance.setSetting("serverPath", value: textField.text!)
        }))
        
        // 4. Present the alert.
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    
    func showMyQRCodePrompt() {
        let alert = UIAlertController(title: "My QRCode", message: "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n", preferredStyle: .Alert)
        var qrCode = QRCode((DataManager.sharedInstance.getSelfUser()?.public_key)!)
        qrCode!.size = CGSize(width: 250, height: 250)
        let myQRImage = qrCode?.image
        let imageView = UIImageView(frame: CGRectMake(10, 50, 250, 250))
        imageView.image = myQRImage
        alert.view.addSubview(imageView)
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        // 4. Present the alert.
        self.presentViewController(alert, animated: true, completion: nil)
    }

}

extension ConversationInboxViewController : NewConversationDelegate {
    func backFromNewMessage(user: User) {
        // the NewMessageSegue created a conversation and is telling us about it, we handle it by switching to view
        // the conversation between you and that user
        self.selectedUser = user
        self.performSegueWithIdentifier("toConvo", sender: self)

    }
}
