//
//  LicensesViewController.swift
//  Franziskaneum
//
//  Created by Niko Kirste on 08.02.16.
//  Copyright © 2016 Franziskaneum. All rights reserved.
//

import UIKit

class LicensesViewController: UIViewController {
    
    // MARK: Properties
    
    @IBOutlet weak var licensesTextView: UITextView!
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        licensesTextView.setContentOffset(CGPoint.zero, animated: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
