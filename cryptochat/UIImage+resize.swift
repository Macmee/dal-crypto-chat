//
//  UIImage+resize.swift
//  cryptochat
//
//  Created by David Zorychta on 2016-04-02.
//  Copyright © 2016 David Zorychta. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    func scaleWithNewWidth(newWidth: CGFloat) -> UIImage {
        let scale = newWidth / self.size.width
        let newHeight = self.size.height * scale
        UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight))
        self.drawInRect(CGRectMake(0, 0, newWidth, newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}