// This is a custom message cell that is rendered in the ConversationViewController
//  MessageTableViewCell.swift
//  cryptochat
//
//  Created by Ario K on 2016-03-12.
//  Copyright © 2016 David Zorychta. All rights reserved.
//

import UIKit

// A color object
var color: UIColor? = nil
// The length of the image that will cascade through conversatinviewcontroller also.
var imageLength : CGFloat = 150.0

class MessageTableViewCell : UITableViewCell {
    // set the cell padding for left and right side the same
    static var cellPadding : CGFloat = 8.0
    // instantiate a speech bubble view
    var bubbleView : SpeechBubbleView = SpeechBubbleView(frame: CGRectZero)
    // the image object for when an image is sent or recieved
    var imgUser : UIImageView = UIImageView(frame: CGRectZero)
    //the current message being rendered
    var currentMessage : Message?
    
    // initialize the message table view cell, set color.
    override class func initialize() {
        if self == MessageTableViewCell.self {
            color = UIColor(red: 220 / 255.0, green: 225 / 255.0, blue: 240 / 255.0, alpha: 1.0)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        // Initializes a table cell with a style and a reuse identifier and returns it to the caller.
        self.selectionStyle = .None
        // Create the speech bubble view
        self.bubbleView = SpeechBubbleView(frame: CGRectZero)
        //_bubbleView.backgroundColor = color;
        // Returns a color object whose grayscale and alpha values are both 0.0.
        self.bubbleView.backgroundColor = UIColor.clearColor()
        // determine whether the view is opaque.
        self.bubbleView.opaque = true
        // whether the view’s bounds should be automatically cleared before drawing.
        self.bubbleView.clearsContextBeforeDrawing = false
        // determine how a view lays out its content when its bounds change.
        self.bubbleView.contentMode = .Redraw
        // view does not resize.
        self.bubbleView.autoresizingMask = UIViewAutoresizing.None
        // attach the bubble view to the main view
        self.contentView.addSubview(bubbleView)
        
        // set the border color for the image view
        self.imgUser.layer.borderColor = UIColor.blueColor().CGColor
        // attach to the main view
        self.contentView.addSubview(imgUser)
    }
    
    // Lays out subviews.
    override func layoutSubviews() {
        super.layoutSubviews()
        // grayscale and alpha values are both 0.0.
        self.backgroundColor = UIColor.clearColor()
    }
    
    // Set up the passed in message for rendering
    func setMessage(message: Message) {
        // Don't render already rendered message, check the unique identifier.
        if message.id == currentMessage?.id {
            return
        }
        // set the current rendering message to the passed in message
        currentMessage = message
        // reset the ImageView object
        imgUser.image = nil
        // alpha value, for imageview
        imgUser.alpha = 0
        // alpha value, for bubbleview
        bubbleView.alpha = 0
        // decrypt the incoming message
        let text = message.decryptedMessage
        // check if the message is an image
        if message.isImage {
            // if it is an image take the string image and convert to a UIImage object
            ImageCom.sharedInstance.toImage(message.imageString) { image in
                // set the image for rendering
                self.setImageMsg(image)
            }
        } else {
            // if it is a text message perform text rendering
            setTextMsg(text)
        }
    }

    // Prepares and renders a text message
    func setTextMsg(text : String) {
        // alpha value, not transparent
        bubbleView.alpha = 1
        // point with the specified coordinates (x,y) coordinates
        var point: CGPoint = CGPointMake(MessageTableViewCell.cellPadding, 0)
        // We display messages that are sent by the user on the left-hand side of
        // the screen. Incoming messages are displayed on the right-hand side.
        var bubbleType: BubbleType
        // find the size of the text that was recieved.
        let bubbleSize: CGSize = SpeechBubbleView.sizeForText(text)
        // determine if the message is from the reciever or the sender
        if (currentMessage?.isFromUser) == false {
            // align the bubble on the left side, the xcoordinate is by default on the left side
            bubbleType = BubbleType.Lefthand
        } else {
            // align the text bubble to the right side
            bubbleType = BubbleType.Righthand
            // set the x coordinate to the right side
            point.x = UIScreen.mainScreen().bounds.size.width - bubbleSize.width - MessageTableViewCell.cellPadding
        }

        // structure that contains the location and dimensions of a rectangle
        var rect: CGRect = CGRect()
        // starting point
        rect.origin = point
        // set the size of the render object
        rect.size = bubbleSize
        // attach the bubble view and the text together in the rect to the bubble view
        self.bubbleView.frame = rect
        // set it on the aligned side
        bubbleView.setText(text, bubbleType: bubbleType)
    }
    
    // Prepares and renderes a image message sent
    func setImageMsg(img: UIImage) {
        // alpha value, not transparent
        imgUser.alpha = 1
        // point with the specified coordinates (x,y)
        var point: CGPoint = CGPointZero
        // Make sure the image of correct width and height
        let newImage = img.scaleToFitSize(CGSizeMake(imageLength, imageLength))
        // determine if the message is from the reciever or the sender
        if (currentMessage?.isFromUser) == false {
            // by default the image is on the left side, just adjust padding
            point.x = MessageTableViewCell.cellPadding
        } else {
            // adjust the image to the right side
            point.x = self.bounds.size.width - imageLength - MessageTableViewCell.cellPadding
        }
        
        //structure that contains the location and dimensions of a rectangle
        var rect: CGRect = CGRect()
        // set the location of the rectangle
        rect.origin = point
        // set the size of the rectangle
        rect.size =  CGSizeMake(imageLength, imageLength)
        // attach the rectangle to the imageview
        imgUser.frame = rect
        // add the image
        imgUser.image = newImage
        // give the image a rounded radius
        imgUser.layer.cornerRadius = 10
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
        //Future implementations perhaps. 
    }
    
    
    
}
