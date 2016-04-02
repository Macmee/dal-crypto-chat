//
//  SpeechBubbleView.swift
//  cryptochat
//
//  Created by Ario K on 2016-03-12.
//  Copyright © 2016 David Zorychta. All rights reserved.
//

import Foundation
import UIKit

// each bubble has this property to keep track if its on the left or right
enum BubbleType : Int {
    // bubble is on the left
    case Lefthand = 0
    // bubble is on the right
    case Righthand
}

// reference to the font used in the chat bubble
let cellFont = UIFont.systemFontOfSize(UIFont.systemFontSize())

// reference to the gray colour used if the message is on the left side (from other user)
let grayColor = UIColor(red: 241.0/255.0, green: 240.0/255.0, blue: 240.0/255.0, alpha: 1.0)

// reference to the blue color used if the message is on the right side (from you)
let blueColor = UIColor(red: 32.0/255.0, green: 146.0/255.0, blue: 247.0/255.0, alpha: 1.0)

// the padding amount to surround each cell
let padding : CGFloat = 10.0

// the speech bubble is the label that contains text in a conversation, we insert this into the cell in a conversation
class SpeechBubbleView: UILabel {

    // this label is used in the sizeForText method below to calculate how tall each bubble will be (tableviews need
    // to know how tall cells are, so they can compute how to render cells)
    static let heightCalculatingLabel = SpeechBubbleView(frame: CGRectZero)

    // maxWidth is the maximum width of a bubble. Purely cosmetic, set to 70% the width of your screen
    static var maxWidth : CGFloat {
        get {
            return UIScreen.mainScreen().bounds.size.width * 0.7
        }
    }

    // is this bubble on the left or right of the screen?
    var bubbleType : BubbleType?

    // required apple method for xib logic
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // set some default properties for all bubbles
    override init(frame: CGRect) {
        // inheritence super call
        super.init(frame: frame)
        // all bubbles have the same (system) font
        font = cellFont
        // all bubbles should be curved with border radius
        clipsToBounds = true
        layer.cornerRadius = 13
        // all bubbles may be multiple lines
        numberOfLines = 0
        // all bubbles should align text to the middle
        textAlignment = .Center
    }

    // this method calculates the height of a bubble given text
    class func sizeForText(text: String) -> CGSize {
        // setup a dummy label with the provided text
        heightCalculatingLabel.text = text
        // set the max width of our dummy variable to 70% and give it unlimited height
        heightCalculatingLabel.frame = CGRectMake(0, 0, SpeechBubbleView.maxWidth, CGFloat.max)
        // now use sizeThatFits to figure out the dimensions required for this text
        var rect = heightCalculatingLabel.sizeThatFits(heightCalculatingLabel.frame.size)
        // add padding onto the computed dimensions
        rect.width += 2*padding
        rect.height += 2*padding
        // return the computed dimensions
        return rect
    }

    // this method is called by the cell and is used to set the text and bubble type (left or right)
    func setText(newText: String, bubbleType newBubbleType: BubbleType) {
        // set the text for the bubble
        self.text = newText
        // set the type (left or right) for the bubble
        self.bubbleType = newBubbleType
        // the bubble is from another user (and thus is on the left)
        if bubbleType == BubbleType.Lefthand {
            // left bubbles should be gray with black text
            backgroundColor = grayColor
            textColor = UIColor.blackColor()
        } else {
            // right bubbles (messages from you) should be blue with white text
            backgroundColor = blueColor
            textColor = UIColor.whiteColor()
        }
    }
}