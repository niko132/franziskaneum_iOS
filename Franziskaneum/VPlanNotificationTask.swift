//
//  VPlanNotificationTask.swift
//  Franziskaneum
//
//  Created by Niko Kirste on 28.01.16.
//  Copyright © 2016 Franziskaneum. All rights reserved.
//

import UIKit
import UserNotifications

class VPlanNotificationTask {
	
	static fileprivate let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
	static fileprivate let ArchiveURL = DocumentsDirectory.appendingPathComponent("vplanNotification")
	
	var startDate: Date?
	let settings = SettingsManager.instance
	
	func performTask(completionHandler: @escaping (_ error: FranziskaneumError?) -> Void) {
		startDate = Date()
		let vplanManager = VPlanManager.instance
		vplanManager.getVPlan(.download, completionHandler: { (vplan: [VPlanDayData]?, mode: VPlanLoadingMode, error: FranziskaneumError?) in
			if let vplan = vplan {
				var changesVPlan: [VPlanDayData] = [VPlanDayData]()
				
				for vplanDay in vplan {
					changesVPlan.append(vplanDay.copy() as! VPlanDayData)
				}
				
				let notificationManager = VPlanNotificationManager.instance
				
				notificationManager.removeOldDays(&changesVPlan)
				notificationManager.filterNotificationVPlan(&changesVPlan)
				
				let savedNotificationVPlan = notificationManager.getSavedNotifications()
				notificationManager.saveNotifications(changesVPlan)
				
				for (index, changesDay) in changesVPlan.enumerated().reversed() {
					for savedDay in savedNotificationVPlan {
						if (savedDay == changesDay) {
							changesVPlan.remove(at: index)
							break
						}
					}
				}
				
				var iconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber
				
				for day in changesVPlan {
					iconBadgeNumber += day.tableData!.count
				}
				
				for day in changesVPlan {
					/**
					let notification = UILocalNotification()
					notification.alertBody = "\(day.getNameOfDay()):\n\(day.tableData!.count) Änderungen"
					notification.alertAction = "Anzeigen"
					notification.fireDate = Date()
					notification.applicationIconBadgeNumber = iconBatchNumber
					notification.userInfo = ["title": day.title!]
					notification.soundName = UILocalNotificationDefaultSoundName
					UIApplication.shared.scheduleLocalNotification(notification)
					**/
					
					let title = day.getNameOfDay()
					let body = day.tableData!.count <= 1 ? "Eine Änderung" : "\(day.tableData!.count) Änderungen"
					let userInfo = ["vplan_day_title" : day.title!]
					
					self.sendNotification(title: title, body: body, iconBadgeNumber: iconBadgeNumber, userInfo: userInfo, identifier: day.title!)
				}
				
				print(self.startDate!.timeIntervalSinceNow)
				
				completionHandler(nil)
			} else if let error = error {
				completionHandler(error)
			} else {
				completionHandler(nil)
			}
		})
	}
	
	func sendNotification(title: String, body: String, iconBadgeNumber: Int, userInfo: [AnyHashable : Any], identifier: String) {
		if #available(iOS 10.0, *) {
			let content = UNMutableNotificationContent()
			content.title = title
			content.body = body
			content.badge = iconBadgeNumber as NSNumber?
			content.sound = UNNotificationSound.default()
			content.userInfo = userInfo
			
			let request = UNNotificationRequest(identifier: "VPlan_\(identifier)", content: content, trigger: nil)
			
			UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
			UNUserNotificationCenter.current().add(request) { (error: Error?) in
				if let error = error {
					print(error)
				}
			}
		} else {
			let notification = UILocalNotification()
			notification.alertTitle = title
			notification.alertBody = body
			notification.userInfo = userInfo
			notification.alertAction = "Anzeigen"
			notification.fireDate = Date()
			notification.applicationIconBadgeNumber = iconBadgeNumber
			notification.soundName = UILocalNotificationDefaultSoundName
			
			UIApplication.shared.scheduleLocalNotification(notification)
		}
	}
	
	/**
	func removeOldDaysFromVPlan(inout vplan: [VPlanDayData]) {
	let dateFormatter = NSDateFormatter()
	dateFormatter.locale = NSLocale(localeIdentifier: "de_DE")
	dateFormatter.dateFormat = "cccc, d. MMMM yyyy"
	
	for i in vplan.count - 1 ... 0 {
	if let title = vplan[i].title {
	if let vplanDate = dateFormatter.dateFromString(title) {
	if vplanDate.timeIntervalSinceNow + (15 * 60 * 60) <= 0 {
	vplan.removeAtIndex(i)
	}
	}
	}
	}
	}
	
	func filterForTeacher(inout vplan: [VPlanDayData]) {
	let teacherShortcut = settings.teacherShortcut!
	
	for i in vplan.count - 1 ... 0 {
	if vplan[i].tableData != nil {
	for j in vplan[i].tableData!.count - 1 ... 0 {
	if TeacherData.nsRangeOfShortcutInString(vplan[i].tableData![j].teacher, teacherShortcut: teacherShortcut) == nil {
	vplan[i].tableData!.removeAtIndex(j)
	}
	}
	}
	
	if vplan[i].tableData == nil || vplan[i].tableData!.count == 0 {
	vplan.removeAtIndex(i)
	}
	}
	}
	
	func filterForAdvancedLevel(inout vplan: [VPlanDayData]) {
	let schoolClassStep = settings.schoolClassStep
	let timetable = TimetableManager.instance.loadTimetable()
	
	for (var i = vplan.count - 1; i >= 0; i--) {
	if vplan[i].tableData != nil {
	for (var j = vplan[i].tableData!.count - 1; j >= 0; j--) {
	if vplan[i].tableData![j].schoolClass == nil || !vplan[i].tableData![j].schoolClass!.containsString(String(schoolClassStep)) || !TimetableData.hasCourse(timetable, course: vplan[i].tableData![j].schoolClass!) {
	vplan[i].tableData!.removeAtIndex(j)
	}
	}
	}
	
	if vplan[i].tableData == nil || vplan[i].tableData!.count == 0 {
	vplan.removeAtIndex(i)
	}
	}
	}
	
	func filterForLowerClass(inout vplan: [VPlanDayData]) {
	let schoolClassStep = settings.schoolClassStep
	let schoolClass = settings.schoolClass
	
	for (var i = vplan.count - 1; i >= 0; i--) {
	if vplan[i].tableData != nil {
	for (var j = vplan[i].tableData!.count - 1; j >= 0; j--) {
	if vplan[i].tableData![j].schoolClass == nil || !vplan[i].tableData![j].schoolClass!.containsString("\(schoolClassStep)/\(schoolClass)") {
	vplan[i].tableData!.removeAtIndex(j)
	}
	}
	}
	
	if vplan[i].tableData == nil || vplan[i].tableData!.count == 0 {
	vplan.removeAtIndex(i)
	}
	}
	}
	
	func getSavedNotificationVPlan() -> [VPlanDayData] {
	return NSKeyedUnarchiver.unarchiveObjectWithFile(VPlanNotificationTask.ArchiveURL.path!) as? [VPlanDayData] ?? []
	}
	
	func saveNotificationVPlan(vplan: [VPlanDayData]) {
	NSKeyedArchiver.archiveRootObject(vplan, toFile: VPlanNotificationTask.ArchiveURL.path!)
	}
	**/
	
}
