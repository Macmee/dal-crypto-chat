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
    var cachedSettings = [String : String]()
    var cachedReadStatus = [String : Bool]()
    var db: SQLiteDB!
    
    init() {
        db = SQLiteDB.sharedInstance()
        createTables()
    }

    func resetDatabase() {
        destroyDatabase()
        createTables()
    }

    func destroyDatabase() {
        myself = nil
        namespace = nil
        db.execute("DROP TABLE IF EXISTS message")
        db.execute("DROP TABLE IF EXISTS user")
        db.execute("DROP TABLE IF EXISTS setting")
    }

    func createTables() {
        db.execute("CREATE TABLE IF NOT EXISTS message(sender text, receiver text, msg TEXT, id varchar(255) PRIMARY KEY, time varchar(255))")
        db.execute("CREATE TABLE IF NOT EXISTS user(username text, public_key text)")
        db.execute("CREATE TABLE IF NOT EXISTS setting(key text, value text)")
        db.execute("CREATE TABLE IF NOT EXISTS read(key text, value varchar(255))")
        if getSetting("serverPath") == nil {
            setSetting("serverPath", value: "http://davidz.xyz:8005")
        }
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

    func setReadStatus(key : String, value : Bool) {
        if cachedReadStatus[key] == value {
            return
        }
        // update th ekey in our local cache
        cachedReadStatus[key] = value
        // perform query to delete the key if its already in the db (to simulate upserting)
        db.execute("DELETE FROM read WHERE key = '\(key)'")
        // insert the key into the db (now we dont have to care about duplicates)
        let valueString = (value ? "1" : "0")
        db.execute("INSERT INTO read(key, value) values('\(key)', '\(valueString)')")
    }

    func getReadStatus(key : String) -> Bool {
        // check our cache first since its quicker than querying the db
        if cachedReadStatus[key] != nil {
            // if we got a cache hit return that
            return cachedReadStatus[key]!
        }
        // perform fetch query
        let result = db.query("SELECT * FROM read WHERE key = '\(key)'")
        // bail if query returns no rows
        if result.count == 0 {
            return false
        }
        // if the query returned rows, grab the first row
        let value = (result[0]["value"] as? String) ?? ""
        // cache the row
        let boolValue = (value == "1" ? true : false)
        cachedReadStatus[key] = boolValue
        // return the row as the value
        return boolValue
    }

    func setSetting(key : String, value : String) {
        // update th ekey in our local cache
        cachedSettings[key] = value
        // perform query to delete the key if its already in the db (to simulate upserting)
        db.execute("DELETE FROM setting WHERE key = '\(key)'")
        // insert the key into the db (now we dont have to care about duplicates)
        db.execute("INSERT INTO setting(key, value) values('\(key)', '\(value)')")
    }

    func getSetting(key : String) -> String? {
        // check our cache first since its quicker than querying the db
        if cachedSettings[key] != nil {
            // if we got a cache hit return that
            return cachedSettings[key]
        }
        // perform fetch query
        let result = db.query("SELECT * FROM setting WHERE key = '\(key)'")
        // bail if query returns no rows
        if result.count == 0 {
            return nil
        }
        // if the query returned rows, grab the first row
        let value = (result[0]["value"] as? String) ?? ""
        // cache the row
        cachedSettings[key] = value
        // return the row as the value
        return value
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
        user.exists = true
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

    func getUserByName(username : String) -> User? {
        let sql = "SELECT * FROM user WHERE username = '\(username)'"
        let result = db.query(sql)
        if result.count == 0 {
            return nil
        }
        return mapSingleUser(result[0])
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
