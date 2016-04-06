//  Customer text field created for the WelcomeViewController
//  CustomTextField.swift
//  cryptochat
//
//  Created by David Zorychta on 2016-03-26.
//  Copyright © 2016 David Zorychta. All rights reserved.
//

import Foundation
import UIKit

class CustomTextField: UITextField {

    @IBInspectable var inset: CGFloat = 0
    
    // give the text bounds
    override func textRectForBounds(bounds: CGRect) -> CGRect {
        return CGRectInset(bounds, inset, inset)
    }
    // Returns the rectangle in which editable text can be displayed.
    override func editingRectForBounds(bounds: CGRect) -> CGRect {
        return textRectForBounds(bounds)
    }
    
}