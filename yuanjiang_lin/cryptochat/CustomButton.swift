//
//  UICustomButton.swift
//  Sudoku
//
//  Created by David Zorychta on 2016-01-21.
//  Copyright © 2016 David Zorychta. All rights reserved.
//

import UIKit

@IBDesignable
public class CustomButton: UIView {

  var view: UIView!
  @IBOutlet weak var button : UIButton!

  func setupXib() {
    view = loadViewFromNib()
    view.frame = bounds
    view.autoresizingMask = [ UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight ]
    addSubview(view)
    button.addTarget(self, action: "buttonTouchDown:", forControlEvents: .TouchDown)
    button.addTarget(self, action: "buttonTouchUp:", forControlEvents: .TouchUpInside)
    button.addTarget(self, action: "buttonTouchUp:", forControlEvents: .TouchUpOutside)
  }

  func loadViewFromNib() -> UIView {
    let bundle = NSBundle(forClass: self.dynamicType)
    let nib = UINib(nibName: "CustomButton", bundle: bundle)
    let view = nib.instantiateWithOwner(self, options: nil)[0] as! UIView
    return view
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupXib()
  }

  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setupXib()
  }

  @IBInspectable var text: String? {
    get {
      return button.titleLabel!.text
    }
    set(text) {
      button.setTitle(text, forState: .Normal)
    }
  }

  func buttonTouchDown(sender: UIButton) {
    UIView.animateWithDuration(0.1, animations: {
      self.button.center.y += 3
    })
  }

  func buttonTouchUp(sender: UIButton) {
    UIView.animateWithDuration(0.1, animations: {
      self.button.center.y -= 3
    })
  }

}
