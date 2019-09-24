//
//  TeacherDetailViewController.swift
//  Franziskaneum
//
//  Created by Niko Kirste on 21.01.16.
//  Copyright © 2016 Franziskaneum. All rights reserved.
//

import UIKit

class TeacherDetailViewController: UIViewController {
    
    // MARK: Properties
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nameContainer: UIView!
    @IBOutlet weak var shortcutLabel: UILabel!
    @IBOutlet weak var shortcutContainer: UIView!
    @IBOutlet weak var subjectsLabel: UILabel!
    @IBOutlet weak var subjectsContainer: UIView!
    @IBOutlet weak var specificTasksLabel: UILabel!
    @IBOutlet weak var specificTasksContainer: UIView!
    @IBOutlet weak var emailLabel: TTTAttributedLabel!
    @IBOutlet weak var emailContainer: UIView!
    
    var teacher: TeacherData?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let teacher = teacher {
            self.navigationItem.title = teacher.name!
            
            if let name = teacher.name, forename = teacher.forename {
                nameLabel.text = "\(forename) \(name)"
            } else if let name = teacher.name {
                nameLabel.text = name
            } else if let forename = teacher.forename {
                nameLabel.text = forename
            } else {
                nameContainer.hidden = true
            }
            
            if let shortcut = teacher.shortcut {
                shortcutLabel.text = shortcut
            } else {
                shortcutContainer.hidden = true
            }
            
            if let subjects = teacher.subjects {
                subjectsLabel.text = subjects
            } else {
                subjectsContainer.hidden = true
            }
            
            if let specificTasks = teacher.specificTasks {
                var tasks = ""
                
                for task in specificTasks.componentsSeparatedByString("\n") {
                    if task.isEmpty {
                        continue
                    }
                    
                    if specificTasks.isEmpty {
                        tasks = "• \(task)\n"
                    } else {
                        tasks += "• \(task)\n"
                    }
                }
                
                specificTasksLabel.text = tasks
            } else {
                specificTasksContainer.hidden = true
            }
            
            TeacherManager.instance.getTeacherList(false, completionHandler: { (teacherList: [TeacherData]?, error: FranziskaneumError?) -> Void in
                if let teacherList = teacherList, teacherName = teacher.name {
                    let escapedName = teacherName.escape()
                    let lowerCaseEscapedName = escapedName.lowercaseString
                    
                    if let teacherForename = teacher.forename where TeacherData.existsTeacherWithSameName(teacherList, teacher: teacher) {
                        let forenameWithoutWhitespace: String
                        
                        if teacherForename.contains(" ") {
                            forenameWithoutWhitespace = teacherForename.substringToIndex(teacherForename.startIndex.advancedBy(teacherForename.indexOf(" ")))
                        } else {
                            forenameWithoutWhitespace = teacherForename
                        }
                        
                        let escapedForename = forenameWithoutWhitespace.escape()
                        let lowerCaseEscapedForename = escapedForename.lowercaseString
                        
                        self.emailLabel.text = "\(lowerCaseEscapedForename).\(lowerCaseEscapedName)@franziskaneum.de"
                    } else {
                        self.emailLabel.text = "\(lowerCaseEscapedName)@franziskaneum.de"
                    }
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
