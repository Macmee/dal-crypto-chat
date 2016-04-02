//
//  DataFetcher.swift
//  CryptoChat
//
//  Created by Xuhui Liu on 2016-03-12.
//  Copyright © 2016 Xuhui Liu. All rights reserved.
//

import UIKit

class DataFetcher: NSObject {

    // to conserve memory, our app only ever utilizes one instance of DataFetcher and shares that instance with this
    // class variable. Singletons such as this are a common design pattern in iOS development
    static let sharedInstance = DataFetcher()

    // send a message to the server, taking a user_id / public_key, message (string) and a callback, to be run when
    // the server has responded. The callback takes a boolean which is true if the message sent and false
    // otherwise
    func sendMessage(to_user_id: String, message: String, completion:(success:Bool) ->Void) {
        // extract the user_id (also known as public_key) from your self user, or empty string if you arent logged in
        // (this case should never happen but we're being cautious here)
        let user_id = DataManager.sharedInstance.getSelfUser()?.public_key ?? ""
        // jump to the background thread, we dont want to block the main UI thread as we do the request
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            // construct the url that we will do the request to in order to send a message
            let url = NSURL(string: DataManager.sharedInstance.getSetting("serverPath")! + "/messages")
            let request = NSMutableURLRequest(URL: url!)
            // the server expects a PUT request with form headers for content-type
            request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.HTTPMethod = "PUT"
            // construct a query string with the payload and attatch it to the request body
            let paramString = "user_id=" + user_id + "&to_user_id=" + to_user_id + "&message=" + message
            request.HTTPBody = paramString.dataUsingEncoding(NSUTF8StringEncoding)
            // perform a blocking request on the background thread with the above parameters
            let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) -> Void in
                // once the request is done, hop back on to the main thread
                dispatch_async(dispatch_get_main_queue(), {
                    // perform the callback on the main thread
                    completion(success:true)
                })
            }
            // required invocation to trigger the request
            task.resume()
        }
    }

    // this method queries the server in order to get new messages. It takes a callback which runs when the server
    // has responded, which has a boolean reporting the success of the request, and an array of message objects
    // returned from the server
    func getMessages(complete:(success: Bool, messages:[Message])->Void) {
        // grab your user id / public key and default to empty string if there's a problem
        let user_id = DataManager.sharedInstance.getSelfUser()?.public_key ?? ""
        // hop on the background thread as not to block the main ui thread with our blocking request
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            // this is where response data will be stored
            var response_data = NSString()
            // build the request path needed to get messages
            let url = NSURL(string: DataManager.sharedInstance.getSetting("serverPath")! + "/messages?user_id=" + user_id)
            let request = NSMutableURLRequest(URL: url!)
            // this is a GET request
            request.HTTPMethod = "GET"
            // configure a session
            let session = NSURLSession.sharedSession()
            // spawn the request object
            let task = session.dataTaskWithRequest(request){ (data, response, error) -> Void in
                // hop on the main thread when we're done
                dispatch_async(dispatch_get_main_queue(), {
                    // return with seccess as false if there was an error
                    if error != nil {
                        complete(success: false, messages: [Message]())
                    // no errors, so we want to now format the text/JSON returned
                    }else{
                        // make an array to store the message objects
                        var messages = [Message]()
                        // parse the NSData returned from the request as an NSString
                        response_data = NSString(data: data!, encoding: NSUTF8StringEncoding)!
                        // parse the NSString as JSON
                        if let data = self.parseJSON(response_data) as? Dictionary<String, AnyObject> {
                            // cast the JSON to an array (of AnyObjects)
                            let json_messages = (data["messages"] as? Array) ?? [AnyObject]()
                            // for each AnyObject in the array construct a Message object and append to our array of
                            // messages
                            for json in json_messages {
                                // extract sender, receiver, msg, id and time from the JSON and make a message object
                                let message = Message(
                                    sender: ((json["user_id"] as? String) ?? ""),
                                    receiver: ((json["to_user_id"] as? String) ?? ""),
                                    msg: ((json["message"] as? String) ?? ""),
                                    id: ((json["id"] as? String) ?? ""),
                                    time: ((json["created_at"] as? String) ?? "")
                                )
                                // insert message object into messages array
                                messages.append(message)
                            }
                        }
                        // fire the completion block with true for success and our array of messages
                        complete(success: true, messages: messages)
                    }
                })
            }
            // invoke the request to begin
            task.resume()
        })
    }

    // takes a string and parses and returns JSON
    func parseJSON(messages:NSString) -> AnyObject
    {
        // decode the string
        let message = messages.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        // jsonDict holds the result of our parsing, we create it separate incase parsing fails, then we return it
        // (a blank dict incase of failure)
        var jsonDict: AnyObject?
        // attempt to convert to JSON
        do {
            jsonDict = try NSJSONSerialization.JSONObjectWithData(message!, options: NSJSONReadingOptions())
        // catch any errors incase we cannot convert the provided string
        }catch let error as NSError {
            print("json error: \(error.localizedDescription)")
        }
        // return the object we parsed
       return jsonDict!
    }

    // query the server for a userobject given a username (string), also takes a completion block with one parameter
    // which is a User object. If no user exists, it returns a user object with user.exists = false
    func getUserByName(username:String, complete:(user:User)->Void) {
        // jump on background thread as not to block main UI thread
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            // this is where we store response data from the request
            var response_data = NSString()
            // construct URL that we need to query
            let url = NSURL(string: DataManager.sharedInstance.getSetting("serverPath")! + "/users/" + username)
            let request = NSMutableURLRequest(URL: url!)
            // grabbing a user is a GET request
            request.HTTPMethod = "GET"
            // we need a session obhect
            let session = NSURLSession.sharedSession()
            // create a request task to perform the actual request
            let task = session.dataTaskWithRequest(request){ (data, response, error) -> Void in
                // hop on the main thread again once the request is done
                dispatch_async(dispatch_get_main_queue(), {
                    // response is the user object we will map the request response onto
                    let response = User()
                    // if an error occured just return this unfilled user
                    if error != nil {
                        complete(user: response)
                    }else{
                        // convert response NSData to a string
                        response_data = NSString(data: data!, encoding: NSUTF8StringEncoding)!
                        // convert string to JSON
                        if let data = self.parseJSON(response_data) as? Dictionary<String, AnyObject> {
                            // map that JSON to our empty user object
                            response.exists = ((data["exists"] as? Bool) ?? false)
                            response.public_key = ((data["public_key"] as? String) ?? "")
                            response.username = ((data["username"] as? String) ?? "")
                        }
                        // invoke callback with newly filled out user object
                        complete(user: response)
                    }
                })
            }
            // invoke the request task
            task.resume()
        })
    }

    // query the server for a userobject given a public key (string), also takes a completion block with one parameter
    // which is a User object. If no user exists, it returns a user object with user.exists = false
    // NOTE: this works identically to the method above
    func getUser(public_key:String, complete:(user:User)->Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            var response_data = NSString()
            let url = NSURL(string: DataManager.sharedInstance.getSetting("serverPath")! + "/public-key/" + public_key)
            if url == nil {
                complete(user: User.dummy())
                return
            }
            let request = NSMutableURLRequest(URL: url!)
            request.HTTPMethod = "GET"
            let session = NSURLSession.sharedSession()
            let task = session.dataTaskWithRequest(request){ (data, response, error) -> Void in
                dispatch_async(dispatch_get_main_queue(), {
                    let response = User()
                    if error != nil {
                        complete(user: response)
                    }else{
                        response_data = NSString(data: data!, encoding: NSUTF8StringEncoding)!
                        if let data = self.parseJSON(response_data) as? Dictionary<String, AnyObject> {
                            response.exists = ((data["exists"] as? Bool) ?? false)
                            response.public_key = ((data["public_key"] as? String) ?? "")
                            response.username = ((data["username"] as? String) ?? "")
                        }
                        complete(user: response)
                    }
                })
            }
            task.resume()
        })
    }

    // register a user, given a username, public key and competion block
    func register(username:String, public_key:String, complete:(success: Bool)->Void) {
        // use background thread so we dont block main thread
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            // this is where we store the response
            var response_data = NSString()
            // build url to register
            let url = NSURL(string: DataManager.sharedInstance.getSetting("serverPath")! + "/users")
            let request = NSMutableURLRequest(URL: url!)
            // registration requires a PUT request with form content-type
            request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.HTTPMethod = "PUT"
            // build body querystring which we send as the payload
            let paramString = "username=" + username + "&public_key=" + public_key
            request.HTTPBody = paramString.dataUsingEncoding(NSUTF8StringEncoding)
            // request requires a sesson
            let session = NSURLSession.sharedSession()
            // make a task to represent the request
            let task = session.dataTaskWithRequest(request){ (data, response, error) -> Void in
                // hop on main thread once request is complete
                dispatch_async(dispatch_get_main_queue(), {
                    // if an error occured invoke the callback with success as false
                    if error != nil {
                        return complete(success: false)
                    }else{
                        // no error occured, convert response NSData to a string
                        response_data = NSString(data: data!, encoding: NSUTF8StringEncoding)!
                        // convert string to json
                        if let data = self.parseJSON(response_data) as? Dictionary<String, AnyObject> {
                            // invoke callback with success as true if user was made and false otherwise
                            complete(success: ((data["success"] as? Bool) ?? false))
                        }
                    }
                })
            }
            // trigger the request
            task.resume()
        })
    }

}
