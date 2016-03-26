//
//  Database.swift
//  cryptochat
//
//  Created by Yuanjiang Lin on 16/3/12.
//  Copyright © 2016年 David Zorychta. All rights reserved.
//
import Foundation

class DataManager {
    //Let's make it a singleton
    static let sharedInstance = DataManager()
    let USER_ID = "Ario Khoshzamir"
    
    var db: SQLiteDB!
    
    init() {
        db = SQLiteDB.sharedInstance()
        //        db.execute("DELETE FROM message")
        db.execute("CREATE TABLE IF NOT EXISTS message(sender varchar(255), receiver varchar(255), msg TEXT, id varchar(255), time varchar(255))")
        //        db.execute("create table if not exists message(sender varchar(30), receiver varchar(30), msg varchar(120), id varchar(50), time varchar(30))")
        //        db.execute("create table if not exists keys(public_key varchar(100), private_key varchar(100))")
        
    }
    
    func initKeys(public_key: String,  private_key: String) {
        let sql = "insert into keys(public_key, private_key) values('\(public_key)','\(private_key)')"
        print("sql: \(sql)")
        let result = db.execute(sql)
        print(result)
    }
    
    func storeMessage(m: Message) {
        let sql = "INSERT INTO message(sender, receiver, msg, id, time) values('\(m.sender)', '\(m.receiver)', '\(m.msg)', '\(m.id)','\(m.time)')"
        print("sql: \(sql)")
        let result = db.execute(sql)
        print(result)
    }
    
    func getMessages(id: String) -> [Message] {
        let sql = "SELECT * FROM message WHERE message.sender='\(id)' OR message.receiver='\(id)'"
        let res = db.query(sql)
        return res.map({ message in
            if USER_ID == message["sender"] as? String {
                return Message(
                    sender: (message["sender"] as? String) ?? "",
                    receiver: (message["receiver"] as? String) ?? "",
                    msg: (message["msg"] as? String) ?? "",
                    id: (message["id"] as? String) ?? "",
                    time: (message["time"] as? String) ?? "",
                    isFromUser: true
                )
            } else {
                return Message(
                    sender: (message["sender"] as? String) ?? "",
                    receiver: (message["receiver"] as? String) ?? "",
                    msg: (message["msg"] as? String) ?? "",
                    id: (message["id"] as? String) ?? "",
                    time: (message["time"] as? String) ?? "",
                    isFromUser: false
                )
            }
            
        })
    }
    
    
}
