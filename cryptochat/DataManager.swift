//  This class handles CRUD operations on the SQLite database. 
//  The operations in this class store all data locally.
//  Database.swift
//  cryptochat
//
//  Created by Yuanjiang Lin on 16/3/12.
//  Copyright © 2016年 David Zorychta. All rights reserved.
//
import Foundation

class DataManager {
    // Singleton object
    static let sharedInstance = DataManager()
    // Every user is a User object
    var myself : User?
    // required parameter for encryption library
    var namespace : String?
    // Caches settings so in the view we do not keep polling the same data
    var cachedSettings = [String : String]()
    // Indicate what has already been cashed
    var cachedReadStatus = [String : Bool]()
    // A SQLite db instance
    var db: SQLiteDB!
    
    init() {
        // DB Singleton
        db = SQLiteDB.sharedInstance()
        // Call the create table function
        createTables()
    }

    func resetDatabase() {
        // Call remove all tables function from database
        destroyDatabase()
        // Re-create the tables
        createTables()
    }

    // Remove all the SQl tables
    func destroyDatabase() {
        // You do not exist anymore
        myself = nil
        namespace = nil
        // Drop all the tables
        db.execute("DROP TABLE IF EXISTS message")
        db.execute("DROP TABLE IF EXISTS user")
        db.execute("DROP TABLE IF EXISTS setting")
    }

    // Create the required SQL tables
    func createTables() {
        // the message table
        db.execute("CREATE TABLE IF NOT EXISTS message(sender text, receiver text, msg TEXT, id varchar(255) PRIMARY KEY, time varchar(255))")
        // the user table
        db.execute("CREATE TABLE IF NOT EXISTS user(username text, public_key text)")
        // the setting table
        db.execute("CREATE TABLE IF NOT EXISTS setting(key text, value text)")
        // the messages already read table
        db.execute("CREATE TABLE IF NOT EXISTS read(key text, value varchar(255))")
        // Changing the server path setting
        if getSetting("serverPath") == nil {
            setSetting("serverPath", value: "http://davidz.xyz:8005")
        }
    }

    // This function creates a random string given a length for unique identifiers
    public func randomStringWithLength (len : Int) -> String {
        // A set of letters
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        //Returns an NSMutableString object initialized with initial storage for a given number of characters
        var randomString : NSMutableString = NSMutableString(capacity: len)
        // create the string
        for (var i=0; i < len; i+=1){
            var length = UInt32 (letters.length)
            var rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.characterAtIndex(Int(rand)))
        }
        
        return randomString as String
    }
    // each client has a unique namespace, fed to the encryption library to use as a seed
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
    
    // Store the messages in to the message table
    func storeMessage(m: Message) {
        // perform this sql statement
        let sql = "INSERT INTO message(sender, receiver, msg, id, time) values('\(m.sender)', '\(m.receiver)', '\(m.msg)', '\(m.id)','\(m.time)')"
        // execute the sql statement
        db.execute(sql)
    }

    // This function check if a specfic message has already been read
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

    // Set the status of the message once it has been read by the user
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

    // Perform setting relation sql executions
    func setSetting(key : String, value : String) {
        // update th ekey in our local cache
        cachedSettings[key] = value
        // perform query to delete the key if its already in the db (to simulate upserting)
        db.execute("DELETE FROM setting WHERE key = '\(key)'")
        // insert the key into the db (now we dont have to care about duplicates)
        db.execute("INSERT INTO setting(key, value) values('\(key)', '\(value)')")
    }

    // Retreive all the setting values from sqlite
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

    // store user data
    func storeUser(m: User) {
        // remove the old public key
        db.execute("DELETE FROM user WHERE public_key = '\(m.public_key)'")
        // insert the new public key
        let sql = "INSERT INTO user(username, public_key) values('\(m.username)', '\(m.public_key)')"
        // perform the sql query
        db.execute(sql)
    }
    
    // A single user given the object
    func mapSingleUser(result : AnyObject) -> User {
        // create the user
        let user = User()
        // set the username
        user.username = (result["username"] as? String) ?? ""
        // set the public key
        user.public_key = (result["public_key"] as? String) ?? ""
        // the user exists
        user.exists = true
        return user
    }
    
    // Retreive the users own public key
    func getSelfUser() -> User? {
        // We need to know ourself a lot throughout the app
        if let user = myself {
            return user
            // Get outself if we don't exist yet
        } else if let id = getSetting("self_id") {
            // return myself
            myself = getUser(id)
            return myself
            // we don't exist
        } else {
            return nil
        }
    }
    // Get user data give the username
    func getUserByName(username : String) -> User? {
        // Query the user table
        let sql = "SELECT * FROM user WHERE username = '\(username)'"
        // execute the query
        let result = db.query(sql)
        // not found
        if result.count == 0 {
            return nil
        }
        //return the user
        return mapSingleUser(result[0])
    }

    // Get the user data give the publickey
    func getUser(public_key : String) -> User? {
        // query the user table
        let sql = "SELECT * FROM user WHERE public_key = '\(public_key)'"
        // execute the query
        let result = db.query(sql)
        // not found
        if result.count == 0 {
            return nil
        }
        // return the user
        return mapSingleUser(result[0])
    }

    // get an array of messages that you have recieved from different users
    func getConversations() -> [Message] {
        if let myself = myself {
            // array of messages
            var table = [ String : Message ]()
            // go through the messages
            for message in getMessages(myself.public_key) {
                // look up the different user IDs
                if let value = table[message.otherUserId()] {
                    // check if we have already got these messages, checking the time
                    if message.time > value.time {
                        // new message
                        table[message.otherUserId()] = message
                    }
                } else {
                    // old message
                    table[message.otherUserId()] = message
                }
            }
            // order the messages
            return table.values.sort({ $0.time > $1.time })
        } else {
            // return the conversation
            return [Message]()
        }
    }
    
    // Get an array of message from one ID
    func getMessages(id: String) -> [Message] {
        // look up the sender and reciever id
        let sql = "SELECT * FROM message WHERE message.sender='\(id)' OR message.receiver='\(id)' ORDER BY time ASC"
        // query the sql statement
        let res = db.query(sql)
        // return the set of messages
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
