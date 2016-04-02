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
    var myself : User?
    var namespace : String?
    var db: SQLiteDB!
    
    init() {
        db = SQLiteDB.sharedInstance()
        //db.execute("DROP TABLE IF EXISTS message")
        //db.execute("DROP TABLE IF EXISTS user")
        db.execute("CREATE TABLE IF NOT EXISTS message(sender text, receiver text, msg TEXT, id varchar(255) PRIMARY KEY, time varchar(255))")
        db.execute("CREATE TABLE IF NOT EXISTS user(username text, public_key text)")
        db.execute("CREATE TABLE IF NOT EXISTS setting(key text, value text)")
        
    }
    
    func initKeys(public_key: String,  private_key: String) {
        let sql = "insert into keys(public_key, private_key) values('\(public_key)','\(private_key)')"
        let result = db.execute(sql)
    }

    public func randomStringWithLength (len : Int) -> String {

        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

        var randomString : NSMutableString = NSMutableString(capacity: len)

        for (var i=0; i < len; i+=1){
            var length = UInt32 (letters.length)
            var rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.characterAtIndex(Int(rand)))
        }
        
        return randomString as String
    }

    func getNamespace() -> String {
        if self.namespace != nil {
            // do nothing
        } else if let namespace = getSetting("namespace") {
            self.namespace = namespace
        } else {
            let namespace = randomStringWithLength(25)
            setSetting("namespace", value: namespace)
            self.namespace = namespace
        }
        return self.namespace!
    }
    
    func storeMessage(m: Message) {
        let sql = "INSERT INTO message(sender, receiver, msg, id, time) values('\(m.sender)', '\(m.receiver)', '\(m.msg)', '\(m.id)','\(m.time)')"
        db.execute(sql)
    }

    func setSetting(key : String, value : String) {
        db.execute("DELETE FROM setting WHERE key = '\(key)'")
        let sql = "INSERT INTO setting(key, value) values('\(key)', '\(value)')"
        db.execute(sql)
    }

    func getSetting(key : String) -> String? {
        let sql = "SELECT * FROM setting WHERE key = '\(key)'"
        let result = db.query(sql)
        if result.count == 0 {
            return nil
        }
        return (result[0]["value"] as? String) ?? ""
    }

    func storeUser(m: User) {
        db.execute("DELETE FROM user WHERE public_key = '\(m.public_key)'")
        let sql = "INSERT INTO user(username, public_key) values('\(m.username)', '\(m.public_key)')"
        db.execute(sql)
    }

    func mapSingleUser(result : AnyObject) -> User {
        let user = User()
        user.username = (result["username"] as? String) ?? ""
        user.public_key = (result["public_key"] as? String) ?? ""
        return user
    }

    func getSelfUser() -> User? {
        if let user = myself {
            return user
        } else if let id = getSetting("self_id") {
            myself = getUser(id)
            return myself
        } else {
            return nil
        }
    }

    func getUser(public_key : String) -> User? {
        let sql = "SELECT * FROM user WHERE public_key = '\(public_key)'"
        let result = db.query(sql)
        if result.count == 0 {
            return nil
        }
        return mapSingleUser(result[0])
    }

    func getConversations() -> [Message] {
        if let myself = myself {
            var table = [ String : Message ]()
            for message in getMessages(myself.public_key) {
                if let value = table[message.otherUserId()] {
                    if message.time > value.time {
                        table[message.otherUserId()] = message
                    }
                } else {
                    table[message.otherUserId()] = message
                }
            }
            return table.values.sort({ $0.time > $1.time })
        } else {
            return [Message]()
        }
    }
    
    func getMessages(id: String) -> [Message] {
        let sql = "SELECT * FROM message WHERE message.sender='\(id)' OR message.receiver='\(id)' ORDER BY time ASC"
        let res = db.query(sql)
        return res.map({ message in
            return Message(
                sender: (message["sender"] as? String) ?? "",
                receiver: (message["receiver"] as? String) ?? "",
                msg: (message["msg"] as? String) ?? "",
                id: (message["id"] as? String) ?? "",
                time: (message["time"] as? String) ?? ""
            )
        })
    }


}
