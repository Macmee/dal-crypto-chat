//  Helper class for resizing UIImages
//  UIImage+resize.swift
//  cryptochat
//
//  Created by David Zorychta on 2016-04-02.
//  Copyright © 2016 David Zorychta. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    // Scale to a square given a size, this is the scale for saving in the database
    func scaleWithNewWidth(newWidth: CGFloat) -> UIImage {
        let scale = newWidth / self.size.width
        let newHeight = self.size.height * scale
        UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight))
        self.drawInRect(CGRectMake(0, 0, newWidth, newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    // Scale some more when rendering the image in the tableview
    func scaleToFitSize(size: CGSize) -> UIImage{
        let scale = CGFloat(max(size.width/self.size.width,
            size.height/self.size.height))
        var bubbleSize: CGSize = CGSize()
        bubbleSize.width  = self.size.width * scale
        bubbleSize.height = self.size.height * scale

        let rr:CGRect = CGRectMake( 0, 0, bubbleSize.width, bubbleSize.height)

        UIGraphicsBeginImageContextWithOptions(size, false, 0);
        self.drawInRect(rr)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }

}