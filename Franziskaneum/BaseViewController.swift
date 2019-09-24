//
//  BaseViewController.swift
//  Franziskaneum
//
//  Created by Niko Kirste on 24.01.16.
//  Copyright © 2016 Franziskaneum. All rights reserved.
//

import UIKit

class BaseViewController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.selectedIndex = SettingsManager.instance.homeCategory
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if SettingsManager.instance.isFirstUse {
            let schoolClassOrTeacherViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SchoolClassOrTeacherViewController")
            
            self.present(schoolClassOrTeacherViewController, animated: true, completion: nil)
        }
        
        // update the teacherlist every week
        let settings = SettingsManager.instance
        let lastTeacherlistRefreshDate = settings.lastTeacherlistRefreshDate
        if lastTeacherlistRefreshDate == nil || lastTeacherlistRefreshDate!.timeIntervalSinceNow + (7 * 24 * 60 * 60) <= 0 {
            TeacherManager.instance.getTeacherList(true, completionHandler: { (teacherList: [TeacherData]?, error: FranziskaneumError?) in
                if let _ = teacherList {
                    settings.setLastTeacherlistRefreshDate(Date())
                }
            })
        }
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
