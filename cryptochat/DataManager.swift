//
//  Database.swift
//  cryptochat
//
//  Created by Yuanjiang Lin on 16/3/12.
//  Copyright © 2016年 David Zorychta. All rights reserved.
//
import Foundation

class DataManager {
    static let sharedInstance = DataManager()
    let USER_ID = "Ario Khoshzamir"
    
    var db: SQLiteDB!
    
    init() {
        db = SQLiteDB.sharedInstance()
        db.execute("DROP TABLE IF EXISTS message")
        db.execute("DROP TABLE IF EXISTS user")
        db.execute("CREATE TABLE IF NOT EXISTS message(sender text, receiver text, msg TEXT, id varchar(255), time varchar(255))")
        db.execute("CREATE TABLE IF NOT EXISTS user(username text, public_key text, is_self text)")
        
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

    func storeUser(m: User) {
        db.execute("DELETE FROM user WHERE public_key = '\(m.public_key)'")
        let is_self = m.is_self ? "yes" : "no"
        let sql = "INSERT INTO user(username, public_key, is_self) values('\(m.username)', '\(m.public_key)', '\(is_self)')"
        print("sql: \(sql)")
        let result = db.execute(sql)
        print(result)
    }

    func mapSingleUser(result : AnyObject) -> User {
        let user = User()
        user.username = (result["username"] as? String) ?? ""
        user.public_key = (result["public_key"] as? String) ?? ""
        user.is_self = ((result["is_self"] as? String) ?? "") == "yes"
        return user
    }

    func getSelfUser(public_key : String) -> User? {
        let sql = "SELECT * FROM user WHERE private_key != ''"
        print("sql: \(sql)")
        let result = db.query(sql)
        if result.count == 0 {
            return nil
        }
        return mapSingleUser(result[0])
    }

    func getUser(public_key : String) -> User? {
        let sql = "SELECT * FROM user WHERE public_key = '\(public_key)'"
        print("sql: \(sql)")
        let result = db.query(sql)
        if result.count == 0 {
            return nil
        }
        return mapSingleUser(result[0])
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
