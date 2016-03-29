//
//  ConversationInboxViewController.swift
//  cryptochat
//
//  Created by Ario K on 2016-03-11.
//  Copyright © 2016 David Zorychta. All rights reserved.
//

import UIKit
import Heimdall

class ConversationInboxViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    var selectedUser : User?
    var messages = [Message]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(false, animated: true)
        // Do any additional setup after loading the view.
        tableView.dataSource = self
        tableView.delegate = self
        reload()
    }

    func reload() {
        self.tableView.reloadData()
        MessageManager.sharedInstance.downloadAndStoreMessages {
            self.messages = DataManager.sharedInstance.getConversations()
            self.tableView.reloadData()
        }
    }

    override func viewWillAppear(animated: Bool) {
        reload()
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ConversationCell", forIndexPath: indexPath)
        let message = messages[indexPath.row]
        cell.detailTextLabel?.text = message.decryptedMessage
        cell.textLabel?.text = "Loading..."
        UserManager.sharedInstance.getUser(message.otherUserId()) { (user) in
            if message.otherUserId() == user.public_key {
                cell.textLabel?.text = user.username
            }
        }
        
        return cell
    }
    

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let message = messages[indexPath.row]
        UserManager.sharedInstance.getUser(message.otherUserId()) { (user) in
            self.selectedUser = user
        }
        self.performSegueWithIdentifier("toConvo", sender: self)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "toConvo") {
            let destinationVC = segue.destinationViewController as! ConversationViewController
            destinationVC.user = selectedUser

        }
    }
    

}
