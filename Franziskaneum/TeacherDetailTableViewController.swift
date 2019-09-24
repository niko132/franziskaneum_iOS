//
//  TeacherDetailTableViewController.swift
//  Franziskaneum
//
//  Created by Niko Kirste on 05.06.16.
//  Copyright © 2016 Franziskaneum. All rights reserved.
//

import UIKit
import MessageUI
import TTTAttributedLabel

class TeacherDetailTableViewController: UITableViewController, TTTAttributedLabelDelegate {
    
    // MARK: Properties
    
    var teacher: TeacherData?
    var teacherList: [TeacherData]?
    var tableData: [Int] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let teacher = teacher {
            if teacher.name != nil || teacher.forename != nil {
                tableData.append(0)
            }
            
            if let _ = teacher.shortcut {
                tableData.append(1)
            }
            
            if let _ = teacher.subjects {
                tableData.append(2)
            }
            
            if let specificTasks = teacher.specificTasks , !specificTasks.isEmpty {
                tableData.append(3)
            }
            
            tableData.append(4) // E-mail is always available
        }
        
        TeacherManager.instance.getTeacherList(false, completionHandler: { (teacherList: [TeacherData]?, error: FranziskaneumError?) -> Void in
            if let teacherList = teacherList {
                self.teacherList = teacherList
                self.tableView.reloadData()
            }
        })
        
        tableView.estimatedRowHeight = 66.0
        tableView.rowHeight = UITableViewAutomaticDimension
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TeacherDetailTableViewCell", for: indexPath) as! TeacherDetailTableViewCell
        
        cell.valueLabel.delegate = nil

        switch tableData[(indexPath as NSIndexPath).row] {
        case 0:
            cell.titleLabel.text = "Name"
            if let name = teacher!.name, let forename = teacher!.forename {
                cell.valueLabel.text = "\(forename) \(name)"
            } else if let name = teacher!.name {
                cell.valueLabel.text = name
            } else if let forename = teacher!.forename {
                cell.valueLabel.text = forename
            }
            break
        case 1:
            cell.titleLabel.text = "Kürzel"
            cell.valueLabel.text = teacher?.shortcut
            break
        case 2:
            cell.titleLabel.text = "Fächer"
            cell.valueLabel.text = teacher?.subjects
            break
        case 3:
            cell.titleLabel.text = "Besondere Aufgaben"
            cell.valueLabel.text = "• \(teacher!.specificTasks!.replacingOccurrences(of: "\n", with: "\n• "))"
            break
        case 4:
            cell.titleLabel.text = "E-Mail"
            if let teacherList = teacherList {
                cell.valueLabel.text = teacher?.email(teacherList)
                cell.valueLabel.delegate = self
                let range = NSMakeRange(0, cell.valueLabel.text!.characters.count)
                cell.valueLabel.addLink(to: URL(string: cell.valueLabel.text!), with: range)
            } else {
                cell.valueLabel.text = ""
            }
            break
        default:
            break
        }

        return cell
    }
    
    // MARK: TTTAttributedLabelDelegate
    
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        if MFMailComposeViewController.canSendMail() {
            let mailViewController = MFMailComposeViewController()
            mailViewController.setToRecipients([url.absoluteString])
            
            present(mailViewController, animated: true, completion: nil)
        } else {
            let alertViewController = UIAlertController(title: "E-Mail konnte nicht gesendet werden", message: "Dein Gerät kann keine E-Mails verschicken.\nÜberprüfe deine Email Konfiguration und versuche es erneut.", preferredStyle: UIAlertControllerStyle.alert)
            alertViewController.addAction(UIAlertAction(title: "OK", style: .default , handler: nil))
            present(alertViewController, animated: true, completion: nil)
        }
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
