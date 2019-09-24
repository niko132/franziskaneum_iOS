//
//  VPlanNotificationManager.swift
//  Franziskaneum
//
//  Created by Niko Kirste on 27.03.16.
//  Copyright © 2016 Franziskaneum. All rights reserved.
//

import Foundation

class VPlanNotificationManager {
	
	let fileVPlanNotification = "vplanNotification"
	
	let vplanNotificationURL: URL!
	
	static let instance = VPlanNotificationManager()
	
	fileprivate init() {
		let fileManager = FileManager.default
		
		var vplanNotificationURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.de.franziskaneum.Franziskaneum")?.appendingPathComponent(fileVPlanNotification)
		let oldVPlanNotificationURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileVPlanNotification)
		
		if let vplanNotificationURL = vplanNotificationURL {
			if let oldURL = oldVPlanNotificationURL, fileManager.fileExists(atPath: oldURL.path) { // old file exists, new not
				do {
					try fileManager.moveItem(at: oldURL, to: vplanNotificationURL)
				} catch {}
			}
		} else {
			vplanNotificationURL = oldVPlanNotificationURL
		}
		
		self.vplanNotificationURL = vplanNotificationURL
	}
	
	func getSavedNotifications() -> [VPlanDayData] {
		NSKeyedUnarchiver.setClass(VPlanDayData.self, forClassName: "VPlanDayData")
		NSKeyedUnarchiver.setClass(VPlanDayData.VPlanTableData.self, forClassName: "VPlanDayData.VPlanTableData")
		NSKeyedUnarchiver.setClass(VPlanDayData.self, forClassName: "Franziskaneum.VPlanDayData")
		NSKeyedUnarchiver.setClass(VPlanDayData.VPlanTableData.self, forClassName: "Franziskaneum.VPlanDayData.VPlanTableData")
		NSKeyedUnarchiver.setClass(VPlanDayData.VPlanTableData.self, forClassName: "VplanDayData.VplanTableData")
		
		return NSKeyedUnarchiver.unarchiveObject(withFile: vplanNotificationURL.path) as? [VPlanDayData] ?? []
	}
	
	func saveNotifications(_ notificationVPlan: [VPlanDayData]) {
		NSKeyedArchiver.setClassName("VPlanDayData", for: VPlanDayData.self)
		NSKeyedArchiver.setClassName("VPlanDayData.VPlanTableData", for: VPlanDayData.VPlanTableData.self)
		
		NSKeyedArchiver.archiveRootObject(notificationVPlan, toFile: vplanNotificationURL.path)
	}
	
	func removeOldDays(_ vplan: inout [VPlanDayData]) {
		for (index, vplanDay) in vplan.enumerated().reversed() {
			if let vplanDate = vplanDay.getDate() {
				if vplanDate.timeIntervalSinceNow + (15 * 60 * 60) <= 0 {
					vplan.remove(at: index)
				}
			}
		}
	}
	
	func filterNotificationVPlan(_ notificationVPlan: inout [VPlanDayData]) {
		let settings = SettingsManager.instance
		if settings.isTeacher {
			let teacherShortcut = settings.teacherShortcut!
			
			for (dayIndex, notificationVPlanDay) in notificationVPlan.enumerated().reversed() {
				if let notificationVPlanDayTable = notificationVPlanDay.tableData {
					for (tableRowIndex, notificationVPlanDayTableRow) in notificationVPlanDayTable.enumerated().reversed() {
						if TeacherData.nsRangeOfShortcutInString(notificationVPlanDayTableRow.teacher as NSString?, teacherShortcut: teacherShortcut) == nil {
							notificationVPlan[dayIndex].tableData!.remove(at: tableRowIndex)
						}
					}
				}
				
				if notificationVPlan[dayIndex].tableData == nil || notificationVPlan[dayIndex].tableData!.isEmpty {
					notificationVPlan.remove(at: dayIndex)
				}
			}
		} else if settings.schoolClassStep >= 11 {
			let schoolClassStep = settings.schoolClassStep
			let timetable = TimetableManager.instance.loadTimetable()
			
			for (dayIndex, notificationVPlanDay) in notificationVPlan.enumerated().reversed() {
				if let notificationVPlanDayTable = notificationVPlanDay.tableData {
					for (tableRowIndex, notificationVPlanDayTableRow) in notificationVPlanDayTable.enumerated().reversed() {
						if notificationVPlanDayTableRow.schoolClass == nil || !notificationVPlanDayTableRow.schoolClass!.contains(String(schoolClassStep)) || !TimetableData.hasCourse(timetable, course: notificationVPlanDayTableRow.schoolClass!) {
							notificationVPlan[dayIndex].tableData!.remove(at: tableRowIndex)
						}
					}
				}
				
				if notificationVPlan[dayIndex].tableData == nil || notificationVPlan[dayIndex].tableData!.count == 0 {
					notificationVPlan.remove(at: dayIndex)
				}
			}
		} else {
			let schoolClassStep = settings.schoolClassStep
			let schoolClass = settings.schoolClass
			
			for (dayIndex, notificationVPlanDay) in notificationVPlan.enumerated().reversed() {
				if let notificationDayTable = notificationVPlanDay.tableData {
					for (tableRowIndex, notificationDayTableRow) in notificationDayTable.enumerated().reversed() {
						if notificationDayTableRow.schoolClass == nil || !notificationDayTableRow.schoolClass!.contains("\(schoolClassStep)/\(schoolClass)") {
							notificationVPlan[dayIndex].tableData!.remove(at: tableRowIndex)
						}
					}
				}
				
				if notificationVPlan[dayIndex].tableData == nil || notificationVPlan[dayIndex].tableData!.count == 0 {
					notificationVPlan.remove(at: dayIndex)
				}
			}
		}
	}
}
