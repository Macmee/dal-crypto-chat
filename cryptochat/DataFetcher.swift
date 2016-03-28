//
//  DataFetcher.swift
//  CryptoChat
//
//  Created by Xuhui Liu on 2016-03-12.
//  Copyright © 2016 Xuhui Liu. All rights reserved.
//

import UIKit

class DataFetcher: NSObject {

    static let sharedInstance = DataFetcher()

    /*function called to send data to server*/
    func SendMessages(user_id: String, to_user_id: String, message: String, completion:(success:Bool) ->Void){
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)){
            let url = NSURL(string: "http://davidz.xyz:8005/messages")
            let request = NSMutableURLRequest(URL: url!)
            request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.HTTPMethod = "PUT"
            let paramString = "user_id=" + user_id + "&to_user_id=" + to_user_id + "&message=" + message
            request.HTTPBody = paramString.dataUsingEncoding(NSUTF8StringEncoding)
            let task = NSURLSession.sharedSession().dataTaskWithRequest(request){
                (let data, let response, let error) in guard let _:NSData = data, let _:NSURLResponse = response where error == nil
                    else{
                        return
                }
                
            }
            dispatch_async(dispatch_get_main_queue(), {
                task.resume()
                completion(success:true)
            })
        }
    }

    func getMessages(user_id:String, complete:(success: Bool, messages:AnyObject)->Void){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            var response_data = NSString()
            let url = NSURL(string: "http://davidz.xyz:8005/messages?user_id=" + user_id)
            let request = NSMutableURLRequest(URL: url!)
            request.HTTPMethod = "GET"
            let session = NSURLSession.sharedSession()
            let task = session.dataTaskWithRequest(request){ (data, response, error) -> Void in
                if error != nil {
                    return
                }else{
                    response_data = NSString(data: data!, encoding: NSUTF8StringEncoding)!
                    complete(success: true, messages: self.parseJSON(response_data))
                }
            }
            dispatch_async(dispatch_get_main_queue(), {
                task.resume()
                
            })
        })
    }

    func parseJSON(messages:NSString) -> AnyObject
    {
        let message = messages.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        var jsonDict: AnyObject?
        do {
            jsonDict = try NSJSONSerialization.JSONObjectWithData(message!, options: NSJSONReadingOptions())
        }catch let error as NSError {
            print("json error: \(error.localizedDescription)")
        }
       return jsonDict!
    }

    func getUserByName(username:String, complete:(user:User)->Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            var response_data = NSString()
            let url = NSURL(string: "http://davidz.xyz:8005/users/" + username)
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

    func getUser(public_key:String, complete:(user:User)->Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            var response_data = NSString()
            let url = NSURL(string: "http://davidz.xyz:8005/public-key/" + public_key)
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

    func register(username:String, public_key:String, complete:(success: Bool)->Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            var response_data = NSString()
            let url = NSURL(string: "http://davidz.xyz:8005/users")
            let request = NSMutableURLRequest(URL: url!)
            request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.HTTPMethod = "PUT"
            let paramString = "username=" + username + "&public_key=" + public_key
            request.HTTPBody = paramString.dataUsingEncoding(NSUTF8StringEncoding)
            let session = NSURLSession.sharedSession()
            let task = session.dataTaskWithRequest(request){ (data, response, error) -> Void in
                dispatch_async(dispatch_get_main_queue(), {
                    if error != nil {
                        return complete(success: false)
                    }else{
                        response_data = NSString(data: data!, encoding: NSUTF8StringEncoding)!
                        if let data = self.parseJSON(response_data) as? Dictionary<String, AnyObject> {
                            complete(success: ((data["success"] as? Bool) ?? false))
                        }
                    }
                })
            }
            task.resume()
        })
    }

}
