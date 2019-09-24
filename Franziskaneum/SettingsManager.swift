//
//  SettingsManager.swift
//  Franziskaneum
//
//  Created by Niko Kirste on 24.01.16.
//  Copyright © 2016 Franziskaneum. All rights reserved.
//

import Foundation
import UIKit

public class SettingsManager: NSObject {
    
    // MARK: Properties
    
    static let instance = SettingsManager()
    
    let userDefaults: UserDefaults!
    
    var isTeacher: Bool
    var schoolClassStep: Int
    var schoolClass: Int
    var teacherShortcut: String?
    var homeCategory: Int
    var hasABWeek: Bool
    var isFirstUse: Bool
    var lastTeacherlistRefreshDate: Date?
    var vplanLastModifiedDate: Date?
    var vplanAuthenticationPassword: String?
    
    fileprivate override init() {
		// User Defaults - Old
		let defaults = UserDefaults.standard
		
		// App Groups Default - New
		let groupDefaults = UserDefaults(suiteName: "group.de.franziskaneum.Franziskaneum")
		
		// Key to track if we migrated
		let didMigrateToAppGroups = "didMigrateToAppGroups"
		
		if let groupDefaults = groupDefaults {
			if !groupDefaults.bool(forKey: didMigrateToAppGroups) {
				for key in defaults.dictionaryRepresentation().keys {
					groupDefaults.set(defaults.dictionaryRepresentation()[key], forKey: key)
				}
				groupDefaults.set(true, forKey: didMigrateToAppGroups)
				groupDefaults.synchronize()
				print("Successfully migrated defaults")
			} else {
				print("No need to migrate defaults")
			}
			
			userDefaults = groupDefaults
		} else {
			print("Unable to create UserDefaults with given app group")
			userDefaults = defaults
		}
        
        isTeacher = userDefaults.bool(forKey: "isTeacher")
        schoolClassStep = userDefaults.integer(forKey: "schoolClassStep")
        schoolClass = userDefaults.integer(forKey: "schoolClass")
        teacherShortcut = userDefaults.string(forKey: "teacherShortcut")
        homeCategory = userDefaults.integer(forKey: "homeCategory")
        hasABWeek = userDefaults.bool(forKey: "hasABWeek")
        isFirstUse = !userDefaults.bool(forKey: "isFirstUse")
        lastTeacherlistRefreshDate = userDefaults.object(forKey: "lastTeacherlistRefreshDate") as? Date
        vplanLastModifiedDate = userDefaults.object(forKey: "vplanLastModifiedDate") as? Date
        vplanAuthenticationPassword = userDefaults.string(forKey: "vplanAuthenticationPassword")
		
		super.init()
    }
	
	func refresh() {
		isTeacher = userDefaults.bool(forKey: "isTeacher")
		schoolClassStep = userDefaults.integer(forKey: "schoolClassStep")
		schoolClass = userDefaults.integer(forKey: "schoolClass")
		teacherShortcut = userDefaults.string(forKey: "teacherShortcut")
		homeCategory = userDefaults.integer(forKey: "homeCategory")
		hasABWeek = userDefaults.bool(forKey: "hasABWeek")
		isFirstUse = !userDefaults.bool(forKey: "isFirstUse")
		lastTeacherlistRefreshDate = userDefaults.object(forKey: "lastTeacherlistRefreshDate") as? Date
		vplanLastModifiedDate = userDefaults.object(forKey: "vplanLastModifiedDate") as? Date
		vplanAuthenticationPassword = userDefaults.string(forKey: "vplanAuthenticationPassword")
	}
	
	@nonobjc
    func setIsTeacher(_ isTeacher: Bool) {
        self.isTeacher = isTeacher
        userDefaults.set(isTeacher, forKey: "isTeacher")
    }
	
	@nonobjc
    func setSchoolClassStep(_ schoolClassStep: Int) {
        self.schoolClassStep = schoolClassStep
        userDefaults.set(schoolClassStep, forKey: "schoolClassStep")
    }
	
	@nonobjc
    func setSchoolClass(_ schoolClass: Int) {
        self.schoolClass = schoolClass
        userDefaults.set(schoolClass, forKey: "schoolClass")
    }
	
	@nonobjc
    func setTeacherShortcut(_ teacherShortcut: String?) {
        self.teacherShortcut = teacherShortcut
        userDefaults.set(teacherShortcut, forKey: "teacherShortcut")
    }
	
	@nonobjc
    func setHomeCategory(_ homeCategory: Int) {
        self.homeCategory = homeCategory
        userDefaults.set(homeCategory, forKey: "homeCategory")
    }
	
	@nonobjc
    func setHasABWeek(_ hasABWeek: Bool) {
        self.hasABWeek = hasABWeek
        userDefaults.set(hasABWeek, forKey: "hasABWeek")
    }
	
	@nonobjc
    func setIsFirstUse(_ isFirstUse: Bool) {
        self.isFirstUse = isFirstUse
        userDefaults.set(!isFirstUse, forKey: "isFirstUse")
    }
	
	@nonobjc
    func setLastTeacherlistRefreshDate(_ lastTeacherlistRefreshDate: Date?) {
        self.lastTeacherlistRefreshDate = lastTeacherlistRefreshDate
        userDefaults.set(lastTeacherlistRefreshDate, forKey: "lastTeacherlistRefreshDate")
    }
    
    func setVPlanLastModifiedDate(_ vplanLastModifiedDate: Date?) {
        self.vplanLastModifiedDate = vplanLastModifiedDate
        userDefaults.set(vplanLastModifiedDate, forKey: "vplanLastModifiedDate")
    }
    
    func setVPlanAuthenticationPassword(_ vplanAuthenticationPassword: String?) {
        self.vplanAuthenticationPassword = vplanAuthenticationPassword
        userDefaults.set(vplanAuthenticationPassword, forKey: "vplanAuthenticationPassword")
    }
    
}
