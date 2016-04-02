//
//  ImageCom.swift
//  ImageGod
//
//  Created by Xuhui Liu on 2016-03-25.
//  Copyright © 2016 Xuhui Liu. All rights reserved.
//

import UIKit

class ImageCom: NSObject {
    
    static let sharedInstance = ImageCom()
    
    func toText(image : UIImage, completion:(text:NSString) -> Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)){
//            let imageData = UIImagePNGRepresentation(image)
            let imageData = UIImageJPEGRepresentation(image , 0.8)
            let base64String = imageData?.base64EncodedDataWithOptions(.Encoding64CharacterLineLength)
//            let base64String = plainData?.base64EncodedDataWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
            dispatch_async(dispatch_get_main_queue(), {
                completion(text: NSString(data: base64String!, encoding: NSUTF8StringEncoding)!);
            })
        }
    }
    
    
    func toImage(text: NSString, completion:(image:UIImage) -> Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)){
            let imageData = NSData(base64EncodedString: text as String, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)!
            dispatch_async(dispatch_get_main_queue(), {
                completion(image: UIImage(data: imageData)!);
            })
        }
        
    }
}
