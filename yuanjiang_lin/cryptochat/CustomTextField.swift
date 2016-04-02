//
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

    override func textRectForBounds(bounds: CGRect) -> CGRect {
        return CGRectInset(bounds, inset, inset)
    }

    override func editingRectForBounds(bounds: CGRect) -> CGRect {
        return textRectForBounds(bounds)
    }
    
}