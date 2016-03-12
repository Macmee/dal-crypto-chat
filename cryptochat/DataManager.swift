//
//  Database.swift
//  cryptochat
//
//  Created by Yuanjiang Lin on 16/3/12.
//  Copyright © 2016年 David Zorychta. All rights reserved.
//

import Cocoa

class DataManager: UIViewController {
    
    var db: SQLiteDB!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        db = SQLiteDB.sharedInstance()
        db.execute("create table if not exists message(sender varchar(30), receiver varchar(30), msg varchar(120), msgID varchar(50), time varchar(30))")
        db.execute("create table if not exists keys(public_key varchar(100), private_key varchar(100))")
        
    }
    
    func initKeys(public_key: String,  private_key: String) {
        let sql = "insert into keys(public_key, private_key) values('\(public_key)','\(private_key)')"
        print("sql: \(sql)")
        let result = db.execute(sql)
        print(result)
    }
    
    func storeMessage(m: Message) {
        let sql = "insert into message(sender, receiver, msg, msgID time) values('\(m.sender)', '\(m.receiver)', '\(m.msg)', '\(m.msgID)','\(m.time)')"
        print("sql: \(sql)")
        let result = db.execute(sql)
        print(result)
    }
    
    func getMessage(id: String) {
        let sql = "select * from message WHERE message.sender='\(id)' OR message.receiver='\(id)'"
        let res = db.execute(sql)
        return res
    }
    
    func getConversations() {
        
    }
    

}
