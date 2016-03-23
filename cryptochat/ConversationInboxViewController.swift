//
//  ConversationInboxViewController.swift
//  cryptochat
//
//  Created by Ario K on 2016-03-11.
//  Copyright © 2016 David Zorychta. All rights reserved.
//

import UIKit

class ConversationInboxViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    var name : String?
    var dataManager: DataManager!

    let filters = [
        "David Zorychta",
        "Xuhui Lu",
        "Yaunjiang Lin",
        "Ario Khoshzamir",
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.dataSource = self
        tableView.delegate = self
        self.dataManager = DataManager.dataManager
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filters.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ConversationCell", forIndexPath: indexPath)
        cell.detailTextLabel?.text = "1 New Message"
        cell.textLabel?.text = filters[indexPath.row]
        
        return cell
    }
    

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print(filters[indexPath.row])
        name = filters[indexPath.row]
        self.performSegueWithIdentifier("toConvo", sender: self)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "toConvo") {
            let destinationVC = segue.destinationViewController as! ConversationViewController
            destinationVC.nameTitle = name
            dataManager.getMessages(name!)
        }
    }
    

}
