//
//  VPlanDayData.swift
//  Franziskaneum
//
//  Created by Niko Kirste on 04.01.16.
//  Copyright © 2016 Franziskaneum. All rights reserved.
//

import Foundation

@objc(VPlanDayData)
public class VPlanDayData: NSObject, NSCoding, NSCopying {
	
	var title: String?
	var absentTeacher: String?
	var absentClasses: String?
	var notAvailableRooms: String?
	var changesTeacher: String?
	var changesClasses: String?
	var changesSupervision: String?
	var additionalInfo: String?
	var modified: String?
	var tableData: [VPlanTableData]?
	
	override init() { }
	
	required public init?(coder aDecoder: NSCoder) {
		super.init()
		
		title = aDecoder.decodeObject(forKey: "title") as? String
		absentTeacher = aDecoder.decodeObject(forKey: "absentTeacher") as? String
		absentClasses = aDecoder.decodeObject(forKey: "absentClasses") as? String
		notAvailableRooms = aDecoder.decodeObject(forKey: "notAvailableRooms") as? String
		changesTeacher = aDecoder.decodeObject(forKey: "changesTeacher") as? String
		changesClasses = aDecoder.decodeObject(forKey: "changesClasses") as? String
		changesSupervision = aDecoder.decodeObject(forKey: "changesSupervision") as? String
		additionalInfo = aDecoder.decodeObject(forKey: "additionalInfo") as? String
		modified = aDecoder.decodeObject(forKey: "modified") as? String
		tableData = aDecoder.decodeObject(forKey: "tableData") as? [VPlanTableData]
	}
	
	public func encode(with aCoder: NSCoder) {
		aCoder.encode(title, forKey: "title")
		aCoder.encode(absentTeacher, forKey: "absentTeacher")
		aCoder.encode(absentClasses, forKey: "absentClasses")
		aCoder.encode(notAvailableRooms, forKey: "notAvailableRooms")
		aCoder.encode(changesTeacher, forKey: "changesTeacher")
		aCoder.encode(changesClasses, forKey: "changesClasses")
		aCoder.encode(changesSupervision, forKey: "changesSupervision")
		aCoder.encode(additionalInfo, forKey: "additionalInfo")
		aCoder.encode(modified, forKey: "modified")
		aCoder.encode(tableData, forKey: "tableData")
	}
	
	func getNameOfDay() -> String {
		if let title = title , title.contains(",") {
			return title.substring(to: title.range(of: ",")!.lowerBound)
		} else {
			return ""
		}
	}
	
	override public func isEqual(_ object: Any?) -> Bool {
		if let object = object as? VPlanDayData {
			// return self.title == object.title && self.absentTeacher == object.absentTeacher && self.absentClasses == object.absentClasses && self.changesTeacher == object.changesTeacher && self.changesClasses == object.changesClasses && self.changesSupervision == object.changesSupervision && self.additionalInfo == object.additionalInfo && self.modified == object.modified && self.tableData! == object.tableData!
			
			return self.title == object.title && self.tableData! == object.tableData!
		}
		
		return false
	}
	
	public func copy(with zone: NSZone?) -> Any {
		let copy = VPlanDayData()
		
		copy.title = title
		copy.absentTeacher = absentTeacher
		copy.absentClasses = absentClasses
		copy.notAvailableRooms = notAvailableRooms
		copy.changesTeacher = changesTeacher
		copy.changesClasses = changesClasses
		copy.changesSupervision = changesSupervision
		copy.additionalInfo = additionalInfo
		copy.modified = modified
		
		if let tableData = tableData {
			copy.tableData = []
			
			for tableRow in tableData {
				copy.tableData!.append(tableRow.copy() as! VPlanDayData.VPlanTableData)
			}
		}
		
		return copy
	}
	
	public func getDate() -> Date! {
		if let title = self.title {
			if let range = title.range(of: "\\d\\d?\\.\\s*\\w*\\s*\\d\\d\\d\\d", options: .regularExpression, range: nil, locale: Locale(identifier: "de_DE")) {
				let dateString = title.substring(with: range)
				
				let dateFormatter = DateFormatter()
				dateFormatter.locale = Locale(identifier: "de_DE")
				dateFormatter.dateFormat = "d. MMMM yyyy"
				
				return dateFormatter.date(from: dateString)
			}
		}
		
		return nil
	}
	
	internal class VPlanTableData: NSObject, NSCoding, NSCopying {
		
		var schoolClass: String?
		var hour: String?
		var subject: String?
		var teacher: String?
		var room: String?
		var info: String?
		
		override init() { }
		
		required init?(coder aDecoder: NSCoder) {
			super.init()
			
			schoolClass = aDecoder.decodeObject(forKey: "schoolClass") as? String
			hour = aDecoder.decodeObject(forKey: "hour") as? String
			subject = aDecoder.decodeObject(forKey: "subject") as? String
			teacher = aDecoder.decodeObject(forKey: "teacher") as? String
			room = aDecoder.decodeObject(forKey: "room") as? String
			info = aDecoder.decodeObject(forKey: "info") as? String
		}
		
		func encode(with aCoder: NSCoder) {
			aCoder.encode(schoolClass, forKey: "schoolClass")
			aCoder.encode(hour, forKey: "hour")
			aCoder.encode(subject, forKey: "subject")
			aCoder.encode(teacher, forKey: "teacher")
			aCoder.encode(room, forKey: "room")
			aCoder.encode(info, forKey: "info")
		}
		
		override func isEqual(_ object: Any?) -> Bool {
			if let object = object as? VPlanTableData {
				return self.schoolClass == object.schoolClass && self.hour == object.hour && self.subject == object.subject && self.teacher == object.teacher && self.room == object.room && self.info == object.info
			}
			
			return false
		}
		
		func copy(with zone: NSZone?) -> Any {
			let copy = VPlanTableData()
			
			copy.schoolClass = schoolClass
			copy.hour = hour
			copy.subject = subject
			copy.teacher = teacher
			copy.room = room
			copy.info = info
			
			return copy
		}
		
		public func string() -> String {
			let hour = self.hour ?? ""
			let subject = self.subject ?? ""
			let schoolClass = self.schoolClass ?? ""
			let teacher = self.teacher ?? ""
			let room = self.room ?? ""
			let info = self.info ?? ""
			
			if SettingsManager.instance.isTeacher {
				return "\(hour). St. \(subject) \(schoolClass) \(room) \(info)".replacingOccurrences(of: "---", with: "").replacingOccurrences(of: "  ", with: " ")
			}
			
			return "\(hour). St. \(subject) \(teacher) \(room) \(info)".replacingOccurrences(of: "---", with: "").replacingOccurrences(of: "  ", with: " ")
		}
		
	}
	
}
