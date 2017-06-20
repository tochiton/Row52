//
//  AnimatedViewController.swift
//  TableViewStory
//
//  Created by Developer on 6/15/17.
//  Copyright © 2017 Developer. All rights reserved.
//

import UIKit
import FLAnimatedImage


class AnimatedViewController: UIViewController {

    
    @IBOutlet weak var gifView: FLAnimatedImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let path = Bundle.main.path(forResource: "giphy", ofType: "gif"){
            if let data = NSData(contentsOfFile: path){
                let gif = FLAnimatedImage(animatedGIFData: data as Data!)
                gifView.animatedImage = gif
            }
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
