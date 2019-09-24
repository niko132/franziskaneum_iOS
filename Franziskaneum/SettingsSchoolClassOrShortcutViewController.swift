//
//  SettingsSchoolClassOrShortcutViewController.swift
//  Franziskaneum
//
//  Created by Niko Kirste on 24.01.16.
//  Copyright © 2016 Franziskaneum. All rights reserved.
//

import UIKit

class SettingsSchoolClassOrShortcutViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate {
    
    // MARK: Properties
    
    @IBOutlet weak var schoolClassPickerView: UIPickerView!
    @IBOutlet weak var shortcutTextField: UITextField!
    
    let settings = SettingsManager.instance
    
    var numberOfComponents = 2
    
    var schoolClassStep: Int {
        get {
            return schoolClassPickerView.selectedRow(inComponent: 0) + 5
        }
    }
    
    var schoolClass: Int {
        get {
            if schoolClassPickerView.numberOfComponents < 2 {
                return 1
            }
            
            return schoolClassPickerView.selectedRow(inComponent: 1) + 1
        }
    }
    
    var shortcut: String? {
        get {
            return shortcutTextField.text
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if settings.isTeacher {
            schoolClassPickerView.isHidden = true
            navigationItem.title = "Kürzel"
            shortcutTextField.text = settings.teacherShortcut
            shortcutTextField.becomeFirstResponder()
        } else {
            shortcutTextField.isHidden = true
            navigationItem.title = "Klasse"
            
            var schoolClassStepIndex = settings.schoolClassStep - 5
            
            if schoolClassStepIndex < 0 {
                schoolClassStepIndex = 0
            }
            
            schoolClassPickerView.selectRow(schoolClassStepIndex, inComponent: 0, animated: false)
            
            if schoolClassStepIndex <= 5 {
                var schoolClassIndex = settings.schoolClass - 1
                
                if schoolClassIndex < 0 {
                    schoolClassIndex = 0
                }
                
                print(schoolClassIndex, terminator: "")
                
                schoolClassPickerView.selectRow(schoolClassIndex, inComponent: 1, animated: false)
            }
            
            toggleNumberOfComponents(schoolClassStepIndex)
        }
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
    
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        navigationController!.popViewController(animated: true)
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

}
