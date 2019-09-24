//
//  TeacherData.swift
//  Franziskaneum
//
//  Created by Niko Kirste on 19.01.16.
//  Copyright © 2016 Franziskaneum. All rights reserved.
//

import UIKit

public class TeacherData: NSObject, NSCoding {
    // MARK: Properties
    
    var name: String?
    var forename: String?
    var shortcut: String?
    var subjects: String?
    var specificTasks: String?
    
    public override init() {
        
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init()
        
        name = aDecoder.decodeObject(forKey: "name") as? String
        forename = aDecoder.decodeObject(forKey: "forename") as? String
        shortcut = aDecoder.decodeObject(forKey: "shortcut") as? String
        subjects = aDecoder.decodeObject(forKey: "subjects") as? String
        specificTasks = aDecoder.decodeObject(forKey: "specificTasks") as? String
    }
    
    func email(_ teacherList: [TeacherData]) -> String {
        let address: String
        
        if let teacherName = self.name {
            let escapedName = teacherName.escape()
            let lowerCaseEscapedName = escapedName.lowercased()
            
            if let teacherForename = self.forename , TeacherData.existsTeacherWithSameName(teacherList, teacher: self) {
                let forenameWithoutWhitespace: String
                
                if teacherForename.contains(" ") {
                    forenameWithoutWhitespace = teacherForename.substring(to: teacherForename.characters.index(teacherForename.startIndex, offsetBy: teacherForename.indexOf(" ")))
                } else {
                    forenameWithoutWhitespace = teacherForename
                }
                
                let escapedForename = forenameWithoutWhitespace.escape()
                let lowerCaseEscapedForename = escapedForename.lowercased()
                
                address = "\(lowerCaseEscapedForename).\(lowerCaseEscapedName)"
            } else {
                address = lowerCaseEscapedName
            }
        } else {
            address = ""
        }
        
        return "\(address)@franziskaneum.de"
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: "name")
        aCoder.encode(forename, forKey: "forename")
        aCoder.encode(shortcut, forKey: "shortcut")
        aCoder.encode(subjects, forKey: "subjects")
        aCoder.encode(specificTasks, forKey: "specificTasks")
    }
    
    func rangeOfShortcutInString(_ teacherString: String?) -> Range<String.Index>? {
        if let teacherString = teacherString, let teacherShortcut = shortcut, let range = teacherString.range(of: teacherShortcut) {
            let startIndex = teacherString.characters.distance(from: teacherString.startIndex, to: range.lowerBound)
            let endIndex = teacherString.characters.distance(from: teacherString.startIndex, to: range.upperBound)
            
            let alphanumeric = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzäöüABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÜ0123456789.")
            
            if (teacherString.characters.distance(from: teacherString.startIndex, to: range.lowerBound) == 0 || !alphanumeric.contains(UnicodeScalar(teacherString.unicodeScalars[teacherString.unicodeScalars.index(teacherString.unicodeScalars.startIndex, offsetBy: startIndex - 1)].value)!)) && (range.upperBound == teacherString.endIndex || !alphanumeric.contains(UnicodeScalar(teacherString.unicodeScalars[teacherString.unicodeScalars.index(teacherString.unicodeScalars.startIndex, offsetBy: endIndex)].value)!)) {
                return range
            }
            
            /**
            if (teacherString.characters.distance(from: teacherString.startIndex, to: range.startIndex) == 0 || !alphanumeric.contains(UnicodeScalar(teacherString.unicodeScalars[teacherString.unicodeScalars.index(teacherString.unicodeScalars.startIndex, offsetBy: startIndex - 1)].value)!)) && (range.distance(from: range.endIndex, to: teacherString.endIndex) == 0 || !alphanumeric.contains(UnicodeScalar(teacherString.unicodeScalars[teacherString.unicodeScalars.index(teacherString.unicodeScalars.startIndex, offsetBy: endIndex)].value))) {
                return range
            }
 **/
        }
        
        return nil
    }
    
    func nsRangeOfShortcutInString(_ teacherString: NSString?) -> NSRange? {
        return TeacherData.nsRangeOfShortcutInString(teacherString, teacherShortcut: shortcut)
    }
	
	func string() -> String {
		let forename = self.forename ?? ""
		let name = self.name ?? ""
		let shortcut = self.shortcut ?? ""
		let subjects = self.subjects ?? ""
		let specificTasks = self.specificTasks ?? ""
		
		return "\(forename) \(name) \(shortcut) \(subjects) \(specificTasks)"
	}
    
    static func nsRangeOfShortcutInString(_ teacherString: NSString?, teacherShortcut: String?) -> NSRange? {
        if let teacherString = teacherString, let teacherShortcut = teacherShortcut , teacherString.contains(teacherShortcut) {
            let range = teacherString.range(of: teacherShortcut)
            
            let alphanumeric = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzäöüABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÜ0123456789.")
            
            if (range.location >= 0 && range.location + range.length <= teacherString.length && (range.location == 0 || !alphanumeric.contains(UnicodeScalar(teacherString.character(at: range.location - 1))!)) && (range.location + range.length == teacherString.length || !alphanumeric.contains(UnicodeScalar(teacherString.character(at: range.location + range.length))!))) {
                return range
            }
        }
        
        return nil
    }
    
    static func getColorForTeacher(_ teacher: TeacherData) -> UIColor {
        var totalHue = 360
        
        let string = teacher.name! + teacher.forename!
        
        for ascii in string.unicodeScalars {
            totalHue += Int(ascii.value)
        }
        
        return UIColor(hue: CGFloat(Double(totalHue % 360) / 360.0), saturation: 0.66, brightness: 0.66, alpha: 1.0)
    }
    
    static func existsTeacherWithSameName(_ teacherList: [TeacherData], teacher: TeacherData) -> Bool {
        for teacherData in teacherList {
            if !teacherData.isEqual(teacher) && teacherData.name == teacher.name {
                return true
            }
        }
        
        return false
    }
    
}
