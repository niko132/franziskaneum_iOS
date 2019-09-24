//
//  SettingsTableViewController.swift
//  Franziskaneum
//
//  Created by Niko Kirste on 24.01.16.
//  Copyright © 2016 Franziskaneum. All rights reserved.
//

import UIKit
import MessageUI

class SettingsTableViewController: UITableViewController {
    
    // MARK: Properties
    
    @IBOutlet weak var isTeacherSwitch: UISwitch!
    @IBOutlet weak var hasABWeekSwitch: UISwitch!
    @IBOutlet weak var schoolClassOrShortcutLabel: UILabel!
    
    let settings = SettingsManager.instance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isTeacherSwitch.setOn(settings.isTeacher, animated: false)
        hasABWeekSwitch.setOn(settings.hasABWeek, animated: false)
        
        toggleSchoolClassOrShortcutText(settings.isTeacher)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func toggleSchoolClassOrShortcutText(_ isTeacher: Bool) {
        if isTeacher {
            schoolClassOrShortcutLabel.text = "Kürzel"
        } else {
            schoolClassOrShortcutLabel.text = "Klasse"
        }
    }
    
    // MARK: TableView data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch (indexPath as NSIndexPath).section {
        case 0:
            switch (indexPath as NSIndexPath).row {
            case 0:
                isTeacherSwitch.setOn(!isTeacherSwitch.isOn, animated: true)
                isTeacherChanged(isTeacherSwitch)
                break
            case 3:
                hasABWeekSwitch.setOn(!hasABWeekSwitch.isOn, animated: true)
                hasABWeekChanged(hasABWeekSwitch)
                break
            default:
                break
            }
            break
        case 1:
            if (indexPath as NSIndexPath).row == 1 {
                if MFMailComposeViewController.canSendMail() {
                    let mailViewController = MFMailComposeViewController()
                    mailViewController.setToRecipients(["app@franziskaneum.de"])
                    mailViewController.setSubject("Franziskaneum App")
                    self.present(mailViewController, animated: true, completion: nil)
                } else {
                    let alertViewController = UIAlertController(title: "E-Mail konnte nicht gesendet werden", message: "Dein Gerät kann keine E-Mails verschicken.\nÜberprüfe deine Email Konfiguration und versuche es erneut.", preferredStyle: UIAlertControllerStyle.alert)
                    alertViewController.addAction(UIAlertAction(title: "OK", style: .default , handler: nil))
                    present(alertViewController, animated: true, completion: nil)
                }
            }
            break
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: Actions
    
    @IBAction func newSchoolClassOrShortcut(_ sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? SettingsSchoolClassOrShortcutViewController {
            if settings.isTeacher {
                settings.setTeacherShortcut(sourceViewController.shortcut)
            } else {
                settings.setSchoolClassStep(sourceViewController.schoolClassStep)
                settings.setSchoolClass(sourceViewController.schoolClass)
                print(sourceViewController.schoolClass)
            }
        }
    }
    
    @IBAction func isTeacherChanged(_ sender: UISwitch) {
        settings.setIsTeacher(sender.isOn)
        toggleSchoolClassOrShortcutText(sender.isOn)
    }
    
    @IBAction func hasABWeekChanged(_ sender: UISwitch) {
        settings.setHasABWeek(sender.isOn)
    }
    
}
