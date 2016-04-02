//
//  SpeechBubbleView.swift
//  cryptochat
//
//  Created by Ario K on 2016-03-12.
//  Copyright © 2016 David Zorychta. All rights reserved.
//

import Foundation
import UIKit

enum BubbleType : Int {
    case Lefthand = 0
    case Righthand
}

let cellFont = UIFont.systemFontOfSize(UIFont.systemFontSize())

let grayColor = UIColor(red: 241.0/255.0, green: 240.0/255.0, blue: 240.0/255.0, alpha: 1.0)

let blueColor = UIColor(red: 32.0/255.0, green: 146.0/255.0, blue: 247.0/255.0, alpha: 1.0)

let padding : CGFloat = 10.0

class SpeechBubbleView: UILabel {

    static let heightCalculatingLabel = SpeechBubbleView(frame: CGRectZero)

    static var maxWidth : CGFloat {
        get {
            return UIScreen.mainScreen().bounds.size.width * 0.4
        }
    }

    var bubbleType:BubbleType?

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        font = cellFont
        clipsToBounds = true
        numberOfLines = 0
        textAlignment = .Center
        layer.cornerRadius = 13
    }
    
    class func sizeForText(text: String) -> CGSize {
        
        heightCalculatingLabel.text = text
        heightCalculatingLabel.frame = CGRectMake(0, 0, SpeechBubbleView.maxWidth, CGFloat.max)
        var rect = heightCalculatingLabel.sizeThatFits(heightCalculatingLabel.frame.size)
        rect.width += 2*padding
        rect.height += 2*padding
        return rect
    }
    
    func setText(newText: String, bubbleType newBubbleType: BubbleType) {
        self.text = newText
        self.bubbleType = newBubbleType
        if bubbleType == BubbleType.Lefthand {
            backgroundColor = grayColor
            textColor = UIColor.blackColor()
        } else {
            backgroundColor = blueColor
            textColor = UIColor.whiteColor()
        }
}
}