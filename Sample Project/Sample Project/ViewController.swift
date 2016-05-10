//
//  ViewController.swift
//  Sample Project
//
//  Created by Zhu Shengqi on 5/7/16.
//  Copyright © 2016 Zhu Shengqi. All rights reserved.
//

import UIKit
import SimplePasscode

class ViewController: UIViewController {

//    @IBOutlet weak var label: UILabel!
    
    var numPadView: NumPadView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        numPadView = NumPadView()
        view.addSubview(numPadView)
        
        numPadView.snp_makeConstraints { (make) in
            make.center.equalTo(view)
        }
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


//    @IBAction func buttonTapped(sender: AnyObject) {
//        SimplePasscode.changePasscode(presentingViewController: self, currentPasscode: "1111") { (newPasscode) in
//            if let newPasscode = newPasscode {
//                self.label.text = newPasscode
//            } else {
//                self.label.text = "canceled"
//            }
//        }
//    }
}

