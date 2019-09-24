//
//  SchoolClassOrTeacherViewController.swift
//  Franziskaneum
//
//  Created by Niko Kirste on 30.01.16.
//  Copyright © 2016 Franziskaneum. All rights reserved.
//

import UIKit

class SchoolClassOrTeacherViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate {
    
    // MARK: Properties
    
    @IBOutlet weak var shortcutTextField: UITextField!
    @IBOutlet weak var schoolClassPickerView: UIPickerView!
    @IBOutlet weak var teachermodeSwitch: UISwitch!
    @IBOutlet weak var teachermodeSwitchContainer: UIView!
    
    @IBOutlet weak var containerHeight: NSLayoutConstraint!
    
    let schoolClassPickerViewHeight: CGFloat = 216.0
    let shortcutTextFieldHeight: CGFloat = 30.0
    
    let settings = SettingsManager.instance
    
    var numberOfComponents = 2

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func toggleNumberOfComponents(_ schoolClassStepIndex: Int) {
        if schoolClassStepIndex > 5 {
            numberOfComponents = 1
        } else {
            numberOfComponents = 2
        }
        
        schoolClassPickerView.reloadAllComponents()
    }
    
    // MARK: PickerView data source
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return numberOfComponents
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {
            return 8
        } else if component == 1 {
            return 6
        }
        
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == 0 {
            return String(row + 5)
        } else if component == 1 {
            return String(row + 1)
        }
        
        return nil
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if component == 0 {
            toggleNumberOfComponents(row)
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
    
    // MARK: Actions
    
    @IBAction func toggleTeachermode(_ sender: UISwitch) {
        if sender.isOn {
            shortcutTextField.isHidden = false
            schoolClassPickerView.isHidden = true
            navigationItem.title = "Kürzel"
            shortcutTextField.becomeFirstResponder()
            
            view.layoutIfNeeded()
            self.containerHeight.constant = self.shortcutTextFieldHeight
            
            UIView.animate(withDuration: 0.2) {
                self.view.layoutIfNeeded()
            }
            
            /**
            let containerOriginY = teachermodeSwitchContainer.frame.origin.y
            self.containerHeight.constant = self.shortcutTextFieldHeight
            
            DispatchQueue.main.async {
                self.teachermodeSwitchContainer.frame.origin.y = containerOriginY
                
                UIView.animate(withDuration: 0.2, animations: {
                    self.teachermodeSwitchContainer.frame.origin.y = self.shortcutTextField.frame.origin.y + self.shortcutTextFieldHeight + 8.0
                })
            }
 **/
        } else {
            shortcutTextField.isHidden = true
            schoolClassPickerView.isHidden = false
            navigationItem.title = "Klasse"
            shortcutTextField.resignFirstResponder()
            
            view.layoutIfNeeded()
            self.schoolClassPickerView.layoutIfNeeded()
            self.containerHeight.constant = self.schoolClassPickerViewHeight
            
            UIView.animate(withDuration: 0.2) {
                self.view.layoutIfNeeded()
            }
            
            /**
            let containerOriginY = teachermodeSwitchContainer.frame.origin.y
            self.containerHeight.constant = self.schoolClassPickerViewHeight
            
            DispatchQueue.main.async {
                self.teachermodeSwitchContainer.frame.origin.y = containerOriginY
                
                UIView.animate(withDuration: 0.2, animations: {
                    self.teachermodeSwitchContainer.frame.origin.y = self.schoolClassPickerViewHeight + 8.0
                })
            }
 **/
        }
    }
    
    @IBAction func save(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "Achtung", message: "Um Benachrichtigungen für Änderungen zu erhalten muss die App im Hintergrund geöffnet sein.\nVergiss bitte nicht jeden Tag auf den Vertretungsplan zu schauen.", preferredStyle: .alert)
        alertController.view.tintColor = UIColor.franziskaneum
        alertController.addAction(UIAlertAction(title: "Aktzeptieren", style: .default, handler: { (action: UIAlertAction) in
            // save data when accepted. Not erlier!
            self.settings.setIsTeacher(self.teachermodeSwitch.isOn)
            self.settings.setSchoolClassStep(self.schoolClassPickerView.selectedRow(inComponent: 0) + 5)
            if self.numberOfComponents == 2 {
                self.settings.setSchoolClass(self.schoolClassPickerView.selectedRow(inComponent: 1) + 1)
            } else {
                self.settings.setSchoolClass(1)
            }
            self.settings.setTeacherShortcut(self.shortcutTextField.text)
            self.settings.setIsFirstUse(false)
            
            self.dismiss(animated: true, completion: nil)
        }))
        
        // needs to be called otherwise warning
        alertController.view.setNeedsLayout()
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func teacherModeTapped(_ sender: UITapGestureRecognizer) {
        teachermodeSwitch.setOn(!teachermodeSwitch.isOn, animated: true)
        toggleTeachermode(teachermodeSwitch)
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

}
