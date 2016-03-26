//
//  DataFetcher.swift
//  CryptoChat
//
//  Created by Xuhui Liu on 2016-03-12.
//  Copyright © 2016 Xuhui Liu. All rights reserved.
//

import UIKit

class DataFetcher: NSObject {

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

    func getUsername(username:String, complete:(success: Bool, messages:AnyObject)->Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            var response_data = NSString()
            let url = NSURL(string: "http://davidz.xyz:8005/users?username=" + username)
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

}
