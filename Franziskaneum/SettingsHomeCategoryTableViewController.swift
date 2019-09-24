//
//  SettingsHomeCategoryTableViewController.swift
//  Franziskaneum
//
//  Created by Niko Kirste on 24.01.16.
//  Copyright © 2016 Franziskaneum. All rights reserved.
//

import UIKit

class SettingsHomeCategoryTableViewController: UITableViewController {
    
    let settings = SettingsManager.instance
    
    var homeCategory: Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        homeCategory = settings.homeCategory
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        
        if (indexPath as NSIndexPath).row == homeCategory {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let oldIndexPath = IndexPath(row: homeCategory, section: 0)
        tableView.cellForRow(at: oldIndexPath)?.accessoryType = .none
        
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        homeCategory = (indexPath as NSIndexPath).row
        settings.setHomeCategory(homeCategory)
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
