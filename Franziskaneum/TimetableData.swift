//
//  TimetableData.swift
//  Franziskaneum
//
//  Created by Niko Kirste on 15.01.16.
//  Copyright © 2016 Franziskaneum. All rights reserved.
//

public class TimetableData: NSObject, NSCoding {
    
    // MARK: Properties
    
    var hour: Int?
    var subject: String?
    var room: String?
    var teacherOrSchoolClass: String?
    var isDoubleHour: Bool?
    
    public override init() {
        
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init()
        
        hour = aDecoder.decodeInteger(forKey: "hour")
        subject = aDecoder.decodeObject(forKey: "subject") as? String
        room = aDecoder.decodeObject(forKey: "room") as? String
        teacherOrSchoolClass = aDecoder.decodeObject(forKey: "teacherOrSchoolClass") as? String
        isDoubleHour = aDecoder.decodeBool(forKey: "isDoubleHour")
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(hour!, forKey: "hour")
        aCoder.encode(subject, forKey: "subject")
        aCoder.encode(room, forKey: "room")
        aCoder.encode(teacherOrSchoolClass, forKey: "teacherOrSchoolClass")
        aCoder.encode(isDoubleHour!, forKey: "isDoubleHour")
    }
    
    static func correctHours(_ timetable: [TimetableData]) {
        var hourCount = 1
        
        for subject in timetable {
            subject.hour = hourCount
            
            if subject.isDoubleHour! {
                hourCount += 2
            } else {
                hourCount += 1
            }
        }
    }
    
    static func getHourForIndex(_ timetable: [TimetableData], subjectIndex: Int) -> Int {
        var hourCount = 1
        
        for (index, subject) in timetable.enumerated() {
            if index == subjectIndex {
                return hourCount
            }
            
            if subject.isDoubleHour! {
                hourCount += 2
            } else {
                hourCount += 1
            }
        }
        
        return hourCount
    }
    
    static func getIndexFourHour(_ timetable: [TimetableData], hour: Int) -> Int {
        for (index, subject) in timetable.enumerated() {
            if subject.hour! == hour || (subject.isDoubleHour! && subject.hour! + 1 == hour) {
                return index
            }
        }
        
        return timetable.count
    }
    
    static func hasCourse(_ timetable: [[[TimetableData]]], course: String) -> Bool {
        for week in timetable {
            for day in week {
                for subject in day {
                    if let subject = subject.subject , !subject.isEmpty && course.contains(subject.trim()) {
                        return true
                    }
                }
            }
            
            if !SettingsManager.instance.hasABWeek {
                break
            }
        }
        
        return false
    }
    
}
