//
//  EnterCodeViewController.swift
//  TableViewStory
//
//  Created by Developer on 6/15/17.
//  Copyright © 2017 Developer. All rights reserved.
//

import UIKit

class EnterCodeViewController: UIViewController {

    
    @IBOutlet weak var barCode: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        barCode.text=""
        barCode.borderStyle = UITextBorderStyle.roundedRect
        
    }

    
    @IBAction func takePhoto(_ sender: Any) {
        
        let localBarCode = barCode.text
        
        performSegue(withIdentifier: "goToCamera", sender: localBarCode)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if  segue.identifier == "goToCamera"{
            let nextScene = segue.destination as! CameraViewController
            //let backItem = UIBarButtonItem()
            //backItem.title = "Scan Again"
            //navigationItem.backBarButtonItem = backItem
            nextScene.stringPassed = sender as! String
        }
    }    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
