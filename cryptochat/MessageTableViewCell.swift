//
//  MessageTableViewCell.swift
//  cryptochat
//
//  Created by Ario K on 2016-03-12.
//  Copyright © 2016 David Zorychta. All rights reserved.
//

import UIKit


var color: UIColor? = nil

class MessageTableViewCell : UITableViewCell {
    var bubbleView : SpeechBubbleView?
    var label : UILabel = UILabel(frame: CGRectZero)
    var imgUser : UIImageView = UIImageView(frame: CGRectZero)
    var currentMessage : Message?
    
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
        self.selectionStyle = .None
        
        // Create the speech bubble view
        self.bubbleView = SpeechBubbleView(frame: CGRectZero)
        //_bubbleView.backgroundColor = color;
        self.bubbleView!.backgroundColor = UIColor.clearColor()
        self.bubbleView!.opaque = true
        self.bubbleView!.clearsContextBeforeDrawing = false
        self.bubbleView!.contentMode = .Redraw
        self.bubbleView!.autoresizingMask = UIViewAutoresizing.None
        self.contentView.addSubview(bubbleView!)
        
        // Create the label
        self.label = UILabel(frame: CGRectZero)
        //_label.backgroundColor = color;
        self.label.backgroundColor = UIColor.clearColor()
        self.label.opaque = true
        self.label.clearsContextBeforeDrawing = false
        self.label.contentMode = .Redraw
        self.label.autoresizingMask = UIViewAutoresizing.None
        self.label.font = UIFont.systemFontOfSize(13)
        //        self.label!.textColor = UIColor(red: 64 / 255.0, green: 64 / 255.0, blue: 64 / 255.0, alpha: 1.0)
        self.label.textColor =  UIColor(red: 220 / 255.0, green: 225 / 255.0, blue: 240 / 255.0, alpha: 1.0)
        //self.label!.textColor = UIColor.whiteColor()
        self.contentView.addSubview(label)

        self.imgUser.layer.borderColor = UIColor.blueColor().CGColor
        self.contentView.addSubview(imgUser)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.backgroundColor = UIColor.clearColor()
    }
    
    func setMessage(message: Message) {

        if message.id == currentMessage?.id {
            return
        }
        currentMessage = message

        imgUser.image = nil
        label.text = nil
        imgUser.alpha = 0
        label.alpha = 0

        let text = message.decryptedMessage
        if message.isImage {
            ImageCom.sharedInstance.toImage(message.imageString) { image in
                self.setImageMsg(image)
            }
        } else {
            setTextMsg(text)
        }
    }

    func setTextMsg(text : String) {
        label.alpha = 1
        var point: CGPoint = CGPointZero
        // We display messages that are sent by the user on the left-hand side of
        // the screen. Incoming messages are displayed on the right-hand side.
        var bubbleType: BubbleType
        let bubbleSize: CGSize = SpeechBubbleView.sizeForText(text)

        if (currentMessage?.isFromUser) == false {
            bubbleType = BubbleType.Lefthand
            self.label.textAlignment = .Left
        } else {
            bubbleType = BubbleType.Righthand
            point.x = self.bounds.size.width - bubbleSize.width
        }

        // Resize the bubble view and tell it to display the message text
        var rect: CGRect = CGRect()
        rect.origin = point
        rect.size = bubbleSize
        self.bubbleView!.frame = rect
        bubbleView!.setText(text, bubbleType: bubbleType)
        label.sizeToFit()
        self.label.frame = CGRectMake(8, bubbleSize.height, self.contentView.bounds.size.width - 16, 16)
    }

    func setImageMsg(img: UIImage) {
        imgUser.alpha = 1
        var point: CGPoint = CGPointZero
        let newImage = img.scaleToFitSize(CGSizeMake(150, 150))
        
        if (currentMessage?.isFromUser) == false {
            point.x = 5
        } else {
            point.x = self.bounds.size.width - 155
        }
        
        var rect: CGRect = CGRect()
        rect.origin = point
        rect.size =  CGSizeMake(150,150)
        imgUser.frame = rect
        imgUser.image = newImage
        imgUser.layer.cornerRadius = 10
    }
    
    override func prepareForReuse() {
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    
    
}
