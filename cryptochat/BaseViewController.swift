//
//  BaseViewController.swift
//  Sudoku
//
//  Created by David Zorychta on 2016-01-20.
//  Copyright © 2016 David Zorychta. All rights reserved.
//

import UIKit

class BaseViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    navigationController?.setNavigationBarHidden(true, animated: false)
    view.backgroundColor = UIColor(red: 0/255, green: 100/255, blue: 148/255, alpha: 1.0)

    // Do any additional setup after loading the view.
  }

  override func preferredStatusBarStyle() -> UIStatusBarStyle {
    return UIStatusBarStyle.LightContent
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

    func error(message : String!, segue : String?) {
        let alert = UIAlertView()
        alert.title = "Uh oh!"
        alert.message = message
        alert.addButtonWithTitle("Okay")
        alert.show()
        if let segue = segue {
            performSegueWithIdentifier(segue, sender: self)
        }
    }

}
