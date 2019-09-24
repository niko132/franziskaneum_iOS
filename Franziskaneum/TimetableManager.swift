//
//  TimetableManager.swift
//  Franziskaneum
//
//  Created by Niko Kirste on 16.01.16.
//  Copyright © 2016 Franziskaneum. All rights reserved.
//

import Foundation

public class TimetableManager {
	
	// MARK: Properties
	let fileTimetable = "timetable"
	
	// MARK: Archiving Paths
	let timetableURL: URL!
	
	static let instance = TimetableManager()
	
	fileprivate init() {
		let fileManager = FileManager.default
		
		var timetableURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.de.franziskaneum.Franziskaneum")?.appendingPathComponent(fileTimetable)
		let oldTimetableURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileTimetable)
		
		if let timetableURL = timetableURL {
			if let oldURL = oldTimetableURL, fileManager.fileExists(atPath: oldURL.path) {
				do {
					try fileManager.moveItem(at: oldURL, to: timetableURL)
				} catch {}
			}
		} else {
			timetableURL = oldTimetableURL
		}
		
		self.timetableURL = timetableURL
	}
	
	public func getTimetable(_ completionHandler: @escaping (_ timetable: [[[TimetableData]]]) -> Void) {
		DispatchQueue.global(qos: .default).async {
			let timetable = self.loadTimetable()
			completionHandler(timetable)
		}
	}
	
	func setTimetable(_ timetable: [[[TimetableData]]]) {
		DispatchQueue.global(qos: .default).async {
			self.saveTimetable(timetable)
		}
	}
	
	fileprivate func saveTimetable(_ timetable: [[[TimetableData]]]) {
		DispatchQueue.global(qos: .default).async {
			NSKeyedArchiver.setClassName("TimetableData", for: TimetableData.self)
			NSKeyedArchiver.archiveRootObject(timetable, toFile: self.timetableURL.path)
		}
	}
	
	func loadTimetable() -> [[[TimetableData]]] {
		NSKeyedUnarchiver.setClass(TimetableData.self, forClassName: "TimetableData")
		NSKeyedUnarchiver.setClass(TimetableData.self, forClassName: "Franziskaneum.TimetableData")
		if let  timetable = NSKeyedUnarchiver.unarchiveObject(withFile: timetableURL.path) as? [[[TimetableData]]] {
			return timetable
		} else {
			return [[[TimetableData](), [TimetableData](), [TimetableData](), [TimetableData](), [TimetableData]()], [[TimetableData](), [TimetableData](), [TimetableData](), [TimetableData](), [TimetableData]()]]
		}
	}
	
}
