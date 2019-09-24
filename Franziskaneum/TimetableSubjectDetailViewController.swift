//
//  TimetableSubjectDetailViewController.swift
//  Franziskaneum
//
//  Created by Niko Kirste on 15.01.16.
//  Copyright © 2016 Franziskaneum. All rights reserved.
//

import UIKit

class TimetableSubjectDetailViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: Properties
    
    @IBOutlet weak var hourLabel: UILabel!
    @IBOutlet weak var subjectTextField: UITextField!
    @IBOutlet weak var roomTextField: UITextField!
    @IBOutlet weak var teacherOrSchoolClassTextField: UITextField!
    @IBOutlet weak var doubleHourSwitch: UISwitch!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var exactWritingNote: UILabel!
    
    @IBOutlet weak var exactWritingNoteHeightConstraint: NSLayoutConstraint!
    
    var day: String!
    var hour: Int!
    var subject: TimetableData?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let subject = subject {
            hourLabel.text = "\(subject.hour!). Stunde"
            subjectTextField.text = subject.subject!
            roomTextField.text = subject.room!
            teacherOrSchoolClassTextField.text = subject.teacherOrSchoolClass!
            doubleHourSwitch.setOn(subject.isDoubleHour!, animated: true)
        } else if let hour = hour {
            hourLabel.text = "\(hour). Stunde"
        }
        
        teacherOrSchoolClassTextField.placeholder = SettingsManager.instance.isTeacher ? "Klasse/Kurs" : "Lehrer"
        
        subjectTextField.becomeFirstResponder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let settings = SettingsManager.instance
        if (settings.isTeacher || settings.schoolClassStep <= 10) {
            exactWritingNoteHeightConstraint.constant = 0.0
            exactWritingNote.isHidden = true
        } else {
            exactWritingNote.setNeedsLayout()
            exactWritingNote.layoutIfNeeded()
            exactWritingNoteHeightConstraint.constant =  exactWritingNote.sizeThatFits(CGSize(width: exactWritingNote.frame.width, height: CGFloat.greatestFiniteMagnitude)).height
            exactWritingNote.isHidden = false
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if textField == subjectTextField {
            roomTextField.becomeFirstResponder()
        } else if textField == roomTextField {
            teacherOrSchoolClassTextField.becomeFirstResponder()
        }
        
        return true
    }
    
    // MARK: Navigation
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        if presentingViewController != nil {
            dismiss(animated: true, completion:  nil)
        } else {
            navigationController!.popViewController(animated: true)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let sender = sender as? UIBarButtonItem, sender === saveButton {
            subject = TimetableData()
            
            subject!.hour = hour
            subject!.subject = subjectTextField.text
            subject!.room = roomTextField.text
            subject!.teacherOrSchoolClass = teacherOrSchoolClassTextField.text
            subject!.isDoubleHour = doubleHourSwitch.isOn
        }
    }
    
    // MARK: Actions
    
    @IBAction func dismissKeyboard(_ sender: UITapGestureRecognizer) {
        subjectTextField.resignFirstResponder()
        roomTextField.resignFirstResponder()
        teacherOrSchoolClassTextField.resignFirstResponder()
    }
    
    @IBAction func doubleHourTapped(_ sender: UITapGestureRecognizer) {
        doubleHourSwitch.setOn(!doubleHourSwitch.isOn, animated: true)
    }
    
}
