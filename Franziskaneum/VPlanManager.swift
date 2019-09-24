//
//  VPlanManager.swift
//  Franziskaneum
//
//  Created by Niko Kirste on 04.01.16.
//  Copyright © 2016 Franziskaneum. All rights reserved.
//

import Foundation

enum VPlanLoadingMode {
	case download
	case ifModified
	case cache
}

class VPlanManager {
	
	let keyVPlanCookie = "vplanCookie"
	let fileVPlanCache = "vplan"
	
	static let instance = VPlanManager()
	
	// MARK: Archiving Paths
	let vplanURL: URL!
	
	fileprivate var cachedVPlan: [VPlanDayData]?
	
	fileprivate let settings = SettingsManager.instance
	fileprivate let reachability: Reachability!
	
	fileprivate var base64Login: String? {
		get {
			if let password = settings.vplanAuthenticationPassword {
				let login = "FranzApp:\(password)"
				return Data(login.utf8).base64EncodedString()
			} else {
				return nil
			}
		}
	}
	
	fileprivate init() {
		reachability = Reachability()
		
		let fileManager = FileManager.default
		
		var vplanURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.de.franziskaneum.Franziskaneum")?.appendingPathComponent(fileVPlanCache)
		let oldVPlanURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileVPlanCache)
		
		if let vplanURL = vplanURL {
			if let oldURL = oldVPlanURL, fileManager.fileExists(atPath: oldURL.path) {
				do {
					try fileManager.moveItem(at: oldURL, to: vplanURL)
				} catch {}
			}
		} else {
			vplanURL = oldVPlanURL
		}
		
		self.vplanURL = vplanURL
	}
	
	/**
	func getVPlan(mode: VPlanLoadingMode, refresh: Bool, completionHandler: (vplan: [VPlanDayData]?, mode: VPlanLoadingMode, error: FranziskaneumError?) -> Void) {
	if mode == .Download {
	if let vplan = downloadedVPlan where !refresh {
	completionHandler(vplan: vplan, mode: .Download, error: nil)
	} else {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
	self.downloadVPlanData() { (data: NSData?, error: FranziskaneumError?) in
	if let data = data {
	let returnValue = self.parseVPlanWithData(data)
	
	if let vplan = returnValue.vplan {
	self.downloadedVPlan = vplan
	self.saveVPlan(vplan)
	
	completionHandler(vplan: vplan, mode: .Download, error: nil)
	} else if let error = returnValue.error {
	completionHandler(vplan: nil, mode: .Download, error: error)
	} else {
	completionHandler(vplan: nil, mode: .Download, error: .UnknownError)
	}
	} else if let error = error {
	completionHandler(vplan: nil, mode: .Download, error: error)
	} else {
	completionHandler(vplan: nil, mode: .Download, error: .UnknownError)
	}
	}
	}
	}
	} else {
	if let vplan = cachedVPlan {
	completionHandler(vplan: vplan, mode: .Cache, error: nil)
	} else {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
	let returnValue = self.cache()
	
	if let vplan = returnValue.vplan {
	completionHandler(vplan: vplan, mode: .Cache, error: nil)
	} else if let error = returnValue.error {
	completionHandler(vplan: nil, mode: .Cache, error: error)
	} else {
	completionHandler(vplan: nil, mode: .Cache, error: .UnknownError)
	}
	}
	}
	}
	}
	**/
	
	func getVPlan(_ mode: VPlanLoadingMode, completionHandler: @escaping (_ vplan: [VPlanDayData]?, _ mode: VPlanLoadingMode, _ error: FranziskaneumError?) -> Void) {
		DispatchQueue.global(qos: .default).async {
			if mode == .cache {
				if let cachedVPlan = self.cachedVPlan {
					completionHandler(cachedVPlan, .cache, nil)
				} else {
					if self.isCachedVPlanAvailable() {
						self.cacheVPlan(completionHandler)
					} else {
						self.downloadVPlan(completionHandler)
					}
				}
			} else if mode == .ifModified {
				self.isNewVPlanAvailable({ (isNewVPlanAvailable: Bool, error: FranziskaneumError?) -> Void in
					if let error = error {
						completionHandler(nil, .ifModified, error)
					} else {
						if isNewVPlanAvailable {
							self.downloadVPlan(completionHandler)
						} else if let cachedVPlan = self.cachedVPlan {
							completionHandler(cachedVPlan, .cache, nil)
						} else {
							if self.isCachedVPlanAvailable() {
								self.cacheVPlan(completionHandler)
							} else {
								self.downloadVPlan(completionHandler)
							}
						}
					}
				})
			} else if mode == .download {
				self.downloadVPlan(completionHandler)
			}
		}
	}
	
	fileprivate func isCachedVPlanAvailable() -> Bool {
		NSKeyedUnarchiver.setClass(VPlanDayData.self, forClassName: "VPlanDayData")
		NSKeyedUnarchiver.setClass(VPlanDayData.VPlanTableData.self, forClassName: "VPlanDayData.VPlanTableData")
		NSKeyedUnarchiver.setClass(VPlanDayData.self, forClassName: "Franziskianeum.VPlanDayData")
		NSKeyedUnarchiver.setClass(VPlanDayData.VPlanTableData.self, forClassName: "Franziskaneum.VPlanDayData.VPlanTableData")
		NSKeyedUnarchiver.setClass(VPlanDayData.VPlanTableData.self, forClassName: "VplanDayData.VplanTableData")
		return NSKeyedUnarchiver.unarchiveObject(withFile: vplanURL.path) as? [VPlanDayData] != nil
	}
	
	internal func isNewVPlanAvailable(_ completionHandler: @escaping (_ isNewVPlanAvailable: Bool, _ error: FranziskaneumError?) -> Void) {
		if let base64Login = base64Login {
			let vplanSession = URLSession(configuration: URLSessionConfiguration.default)
			var vplanRequest = URLRequest(url: URL(string: "http://www.franziskaneum.de/vplan/vplank.xml")!)
			vplanRequest.httpMethod = "HEAD"
			vplanRequest.addValue("Basic \(base64Login)", forHTTPHeaderField: "Authorization")
			let vplanTask = vplanSession.dataTask(with: vplanRequest, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
				if let response = response as? HTTPURLResponse {
					if response.statusCode == 401 {
						completionHandler(false, FranziskaneumError.authenticationFailed)
					} else {
						if let lastModifiedString = response.allHeaderFields["Last-Modified"] as? String {
							let dateFormatter = DateFormatter()
							dateFormatter.locale = Locale(identifier: "en_US")
							dateFormatter.dateFormat = "EEE',' dd' 'MMM' 'yyyy HH':'mm':'ss zzz"
							
							if let lastModifiedDate = dateFormatter.date(from: lastModifiedString) {
								let vplanLastModifiedDate = self.settings.vplanLastModifiedDate
								
								if vplanLastModifiedDate == nil || vplanLastModifiedDate!.timeIntervalSince(lastModifiedDate) < 0 {
									completionHandler(true, nil)
								} else {
									completionHandler(false, nil)
								}
							} else {
								completionHandler(false, nil)
							}
						} else {
							completionHandler(false, nil)
						}
					}
				} else {
					completionHandler(false, FranziskaneumError.networkError)
				}
			})
			vplanTask.resume()
		} else {
			completionHandler(false, FranziskaneumError.authenticationFailed)
		}
	}
	
	/**
	fileprivate func isAuthenticated() -> Bool {
	if let password = settings.vplanAuthenticationPassword, password == VPlanManager.VPlanAuthenticationPassword {
	return true
	}
	
	return false
	}
	**/
	
	/**
	fileprivate func isAuthenticated(_ completionHandler: @escaping (_ isAuthenticated: Bool, _ error: FranziskaneumError?) -> Void) {
	if let password = settings.vplanAuthenticationPassword {
	let vplanSession = URLSession(configuration: URLSessionConfiguration.default)
	var vplanRequest = URLRequest(url: URL(string: "http://www.franziskaneum.de/vplan/vplank.xml")!)
	vplanRequest.httpMethod = "HEAD"
	
	let login = "FranzApp:\(password)"
	let base64Login = Data(login.utf8).base64EncodedString()
	
	vplanRequest.addValue("Basic \(base64Login)", forHTTPHeaderField: "Authorization")
	let vplanTask = vplanSession.dataTask(with: vplanRequest, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
	if let response = response as? HTTPURLResponse {
	completionHandler(response.statusCode != 401, nil)
	} else {
	completionHandler(false, FranziskaneumError.networkError)
	}
	})
	vplanTask.resume()
	} else {
	completionHandler(false, nil)
	}
	}
	**/
	
	fileprivate func downloadVPlan(_ completionHandler: @escaping (_ vplan: [VPlanDayData]?, _ mode: VPlanLoadingMode, _ error: FranziskaneumError?) -> Void) {
		downloadVPlanData({ (data: Data?, error: FranziskaneumError?) -> Void in
			if let data = data {
				let returnValue = self.parseVPlanWithData(data)
				
				if let downloadedVPlan = returnValue.vplan {
					self.cachedVPlan = downloadedVPlan
					self.saveVPlan(downloadedVPlan)
					
					completionHandler(downloadedVPlan, .download, nil)
				} else if let error = returnValue.error {
					completionHandler(nil, .download, error)
				} else {
					completionHandler(nil, .download, .unknownError)
				}
			} else if let error = error {
				completionHandler(nil, .download, error)
			} else {
				completionHandler(nil, .download, .unknownError)
			}
		})
	}
	
	fileprivate func downloadVPlanData(_ completionHandler: @escaping (_ data: Data?, _ error: FranziskaneumError?) -> Void) {
		if let base64Login = base64Login {
			let vplanSession = URLSession(configuration: URLSessionConfiguration.default)
			var vplanRequest = URLRequest(url: URL(string: "http://www.franziskaneum.de/vplan/vplank.xml")!)
			vplanRequest.httpMethod = "GET"
			vplanRequest.addValue("Basic \(base64Login)", forHTTPHeaderField: "Authorization")
			let vplanTask = vplanSession.dataTask(with: vplanRequest, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
				if let response = response as? HTTPURLResponse {
					if response.statusCode == 401 {
						completionHandler(nil, FranziskaneumError.authenticationFailed)
					} else {
						if let lastModifiedString = response.allHeaderFields["Last-Modified"] as? String {
							let dateFormatter = DateFormatter()
							dateFormatter.locale = Locale(identifier: "en_US")
							dateFormatter.dateFormat = "EEE',' dd' 'MMM' 'yyyy HH':'mm':'ss zzz"
							if let lastModifiedDate = dateFormatter.date(from: lastModifiedString) {
								self.settings.setVPlanLastModifiedDate(lastModifiedDate)
							}
						}
						
						if let data = data {
							completionHandler(data, nil)
						} else {
							completionHandler(nil, .networkError)
						}
					}
				} else {
					completionHandler(nil, FranziskaneumError.networkError)
				}
			})
			vplanTask.resume()
		} else {
			completionHandler(nil, FranziskaneumError.authenticationFailed)
		}
	}
	
	func parseVPlanWithData(_ data: Data) -> (vplan: [VPlanDayData]?, error: FranziskaneumError?) {
		let parser = TFHpple(data: data, encoding: "UTF-8", isXML: true)
		
		var vplan: [VPlanDayData]?
		
		if let vplanElement = (parser?.search(withXPathQuery: "//vp") as! [TFHppleElement]).first {
			vplan = [VPlanDayData]()
			
			var vplanDay: VPlanDayData?
			var vplanTableRow: VPlanDayData.VPlanTableData?
			
			for childElement in vplanElement.search(withXPathQuery: "//*") as! [TFHppleElement] {
				let tagName = childElement.tagName
				
				if tagName == "kopf" {
					vplanDay = VPlanDayData()
					vplan?.append(vplanDay!)
				} else if vplanDay != nil {
					if tagName == "titel" {
						vplanDay?.title = childElement.content?.trim()
					} else if tagName == "datum" {
						vplanDay?.modified = childElement.content?.trim()
					} else if tagName == "abwesendl" {
						vplanDay?.absentTeacher = childElement.content?.trim()
					} else if tagName == "abwesendk" {
						vplanDay?.absentClasses = childElement.content?.trim()
					} else if tagName == "abwesendr" {
						vplanDay?.notAvailableRooms = childElement.content?.trim()
					} else if tagName == "aenderungl" {
						vplanDay?.changesTeacher = childElement.content?.trim()
					} else if tagName == "aenderungk" {
						vplanDay?.changesClasses = childElement.content?.trim()
					} else if tagName == "aufsichtinfo" {
						if vplanDay?.changesSupervision == nil {
							vplanDay?.changesSupervision = childElement.content?.trim()
						} else {
							vplanDay!.changesSupervision! += "\n"
							vplanDay!.changesSupervision! += childElement.content!.trim()
						}
					} else if tagName == "fussinfo" {
						if vplanDay?.additionalInfo == nil {
							vplanDay?.additionalInfo = childElement.content?.trim()
						} else {
							vplanDay!.additionalInfo! += "\n"
							vplanDay!.additionalInfo! += childElement.content!.trim()
						}
					} else if tagName == "haupt" {
						vplanDay?.tableData = []
					} else if vplanDay?.tableData != nil {
						if tagName == "aktion" {
							vplanTableRow = VPlanDayData.VPlanTableData()
							vplanDay?.tableData?.append(vplanTableRow!)
						} else if vplanTableRow != nil {
							if tagName == "klasse" {
								vplanTableRow?.schoolClass = childElement.content?.trim()
							} else if tagName == "stunde" {
								vplanTableRow?.hour = childElement.content?.trim()
							} else if tagName == "fach" {
								vplanTableRow?.subject = childElement.content?.trim()
							} else if tagName == "lehrer" {
								vplanTableRow?.teacher = childElement.content?.trim()
							} else if tagName == "raum" {
								vplanTableRow?.room = childElement.content?.trim()
							} else if tagName == "info" {
								vplanTableRow?.info = childElement.content?.trim()
							}
						}
					}
				}
			}
		}
		
		return (vplan, nil)
	}
	
	/**
	private func downloadVPlanData(completionHandler: (data: NSData?, error: FranziskaneumError?) -> Void) {
	let userDefaults = NSUserDefaults.standardUserDefaults()
	let cookiesString = userDefaults.stringForKey(VPlanManager.KeyVPlanCookie)
	
	if let cookiesString = cookiesString {
	let vplanSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
	let vplanRequest = NSMutableURLRequest(URL: NSURL(string: "http://www.franziskaneum.de/wordpress/schule/planung/vertretungsplan/")!)
	vplanRequest.HTTPShouldHandleCookies = false
	vplanRequest.HTTPMethod = "GET"
	vplanRequest.addValue(cookiesString, forHTTPHeaderField: "Cookie")
	let vplanTask = vplanSession.dataTaskWithRequest(vplanRequest, completionHandler: { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
	if let data = data {
	completionHandler(data: data, error: nil)
	} else {
	completionHandler(data: nil, error: .NetworkError)
	}
	})
	vplanTask.resume()
	} else {
	completionHandler(data: nil, error: .AuthenticationFailed)
	}
	}
	**/
	
	/**
	func parseVPlanWithData(data: NSData) -> (vplan: [VPlanDayData]?, error: FranziskaneumError?) {
	let parser = TFHpple(data: data, isXML: false)
	
	let articles = parser.searchWithXPathQuery("//article") as! [TFHppleElement]
	
	if articles.count == 0 {
	return (nil, .AuthenticationFailed)
	}
	
	let article = articles.first!
	
	if (article.searchWithXPathQuery("//form") as NSArray).count > 0 {
	return (nil, .AuthenticationFailed)
	}
	
	// begin to parse
	
	let elements = article.searchWithXPathQuery("//*") as! [TFHppleElement]
	let size = elements.count
	var current: TFHppleElement
	
	var vplan: [VPlanDayData]!
	
	var dayData: VPlanDayData!
	
	for var index = 0; index < size; index++ {
	current = elements[index]
	
	if let classAttribute = current.objectForKey("class") {
	if classAttribute.containsString("vpfuer") {
	current = elements[++index]
	
	if vplan == nil {
	vplan = [VPlanDayData]()
	}
	
	dayData = VPlanDayData()
	vplan! += [dayData!]
	dayData.title = current.content.nilIfEmpty()
	} else if dayData != nil {
	if classAttribute.containsString("vpdatum") {
	dayData.modified = current.content.nilIfEmpty()
	} else if classAttribute.containsString("thkopfabwesend") {
	if current.text().containsIgnoreCase("Abwesende Lehrer") {
	current = elements[++index]
	if let classAttribute = current.objectForKey("class") {
	if classAttribute.containsString("thabwesend") {
	dayData.absentTeacher = current.content.nilIfEmpty()
	}
	}
	} else if current.text().containsIgnoreCase("Abwesende Klassen") {
	current = elements[++index]
	if let classAttribute = current.objectForKey("class") {
	if classAttribute.containsString("thabwesend") {
	dayData.absentClasses = current.content.nilIfEmpty()
	}
	}
	} else if current.text().containsIgnoreCase("Nicht verfügbare Räume") {
	current = elements[++index]
	if let classAttribute = current.objectForKey("class") {
	if classAttribute.containsString("thabwesend") {
	dayData.notAvailableRooms = current.content.nilIfEmpty()
	}
	}
	} else if current.text().containsIgnoreCase("Lehrer mit Änderung") {
	current = elements[++index]
	if let classAttribute = current.objectForKey("class") {
	if classAttribute.containsString("thabwesend") {
	dayData.changesTeacher = current.content.nilIfEmpty()
	}
	}
	} else if current.text().containsIgnoreCase("Klassen mit Änderung") {
	current = elements[++index]
	if let classAttribute = current.objectForKey("class") {
	if classAttribute.containsString("thabwesend") {
	dayData.changesClasses = current.content.nilIfEmpty()
	}
	}
	}
	} else if classAttribute .containsString("aufsichtendetails") {
	if let changesSupervision = current.content.nilIfEmpty() {
	if dayData.changesSupervision == nil {
	dayData.changesSupervision = changesSupervision
	} else {
	dayData.changesSupervision! += "\n" + changesSupervision
	}
	}
	} else if classAttribute.containsString("ueberschrift") {
	if let text = current.text() where text.containsIgnoreCase("Zusätzliche Informationen") {
	index += 2
	current = elements[index]
	
	dayData.additionalInfo = current.content.trim().nilIfEmpty()
	index++
	}
	}
	}
	}
	
	if let text = current.text() where dayData != nil && text.containsIgnoreCase("Geänderte Unterrichtsstunden") {
	index += 2
	current = elements[index]
	
	let trs = current.searchWithXPathQuery("//tr") as! [TFHppleElement]
	
	for var i = 1; i < trs.count; i++ {
	let tableColumnElements = trs[i].searchWithXPathQuery("//*[contains(@class, 'tdaktionen')]") as! [TFHppleElement]
	
	if dayData.tableData == nil {
	dayData.tableData = []
	}
	
	if tableColumnElements.count >= 6 {
	let tableData = VPlanDayData.VPlanTableData()
	dayData.tableData! += [tableData]
	
	tableData.schoolClass = tableColumnElements[0].content.nilIfEmpty()
	tableData.hour = tableColumnElements[1].content.nilIfEmpty()
	tableData.subject = tableColumnElements[2].content.nilIfEmpty()
	tableData.teacher = tableColumnElements[3].content.nilIfEmpty()
	tableData.room = tableColumnElements[4].content.nilIfEmpty()
	tableData.info = tableColumnElements[5].content.nilIfEmpty()
	}
	}
	}
	
	/**
	if let classAttribute = current.objectForKey("class") {
	if classAttribute == "vpfuerdatum" {
	if vplan == nil {
	vplan = [VPlanDayData]()
	}
	
	dayData = VPlanDayData()
	vplan! += [dayData!]
	
	dayData.title = current.content.nilIfEmpty()
	}
	}
	
	if let currentText = current.text() {
	if currentText == "Gymnasium Franziskaneum" {
	current = elements[index + 2]
	if current.tagName == "strong" {
	dayData.modified = current.content.nilIfEmpty()
	
	index += 2
	}
	} else if currentText == "Abwesende Lehrer:" {
	current = elements[index + 1]
	dayData.absentTeacher = current.content.nilIfEmpty()
	index += 1
	} else if currentText == "Abwesende Klassen:" {
	current = elements[index + 1]
	dayData.absentClasses = current.content.nilIfEmpty()
	index += 1
	} else if currentText == "Lehrer mit Änderung:" {
	current = elements[index + 1]
	dayData.changesTeacher = current.content.nilIfEmpty()
	index += 1
	} else if currentText == "Klassen mit Änderung:" {
	current = elements[index + 1]
	dayData.changesClasses = current.content.nilIfEmpty()
	index += 1
	} else if currentText == "Zusätzliche Informationen:" {
	changedLessons = false
	additionalInfo = true
	} else if currentText == "Geänderte Unterrichtsstunden:" {
	additionalInfo = false
	changedLessons = true
	}
	}
	
	if let classAttribute = current.objectForKey("class") {
	if classAttribute == "aufsichtendetails" {
	if let changesSupervisions = current.content.nilIfEmpty() {
	if dayData.changesSupervision == nil {
	dayData.changesSupervision = changesSupervisions
	} else {
	dayData.changesSupervision! += "\n" + changesSupervisions
	}
	}
	}
	}
	
	if additionalInfo && current.tagName == "tr" {
	for td in current.searchWithXPathQuery("//td") as! [TFHppleElement] {
	if let additionalInfo = td.content.nilIfEmpty() {
	if dayData.additionalInfo == nil {
	dayData.additionalInfo = additionalInfo
	} else {
	dayData.additionalInfo! += "\n" + additionalInfo
	}
	}
	}
	}
	
	if changedLessons && current.tagName == "table" {
	for tr in current.searchWithXPathQuery("//tr") as! [TFHppleElement] {
	
	let tds = tr.searchWithXPathQuery("//td") as! [TFHppleElement]
	
	if tds.count > 0 {
	if dayData.tableData == nil {
	dayData.tableData = []
	}
	
	let tableData = VPlanDayData.VPlanTableData()
	dayData.tableData! += [tableData]
	
	tableData.schoolClass = tds[0].content.nilIfEmpty()
	tableData.hour = tds[1].content.nilIfEmpty()
	tableData.subject = tds[2].content.nilIfEmpty()
	tableData.teacher = tds[3].content.nilIfEmpty()
	tableData.room = tds[4].content.nilIfEmpty()
	tableData.info = tds[5].content.nilIfEmpty()
	}
	}
	
	changedLessons = false
	}
	**/
	}
	
	return (vplan, nil)
	}
	**/
	**/
	**/
	
	public func saveVPlan(_ vplan: [VPlanDayData]) {
		NSKeyedArchiver.setClassName("VPlanDayData", for: VPlanDayData.self)
		NSKeyedArchiver.setClassName("VPlanDayData.VPlanTableData", for: VPlanDayData.VPlanTableData.self)
		NSKeyedArchiver.archiveRootObject(vplan, toFile: vplanURL.path)
	}
	
	func cacheVPlan(_ completionHandler: (_ vplan: [VPlanDayData]?, _ mode: VPlanLoadingMode, _ error: FranziskaneumError?) -> Void) {
		NSKeyedUnarchiver.setClass(VPlanDayData.self, forClassName: "VPlanDayData")
		NSKeyedUnarchiver.setClass(VPlanDayData.VPlanTableData.self, forClassName: "VPlanDayData.VPlanTableData")
		NSKeyedUnarchiver.setClass(VPlanDayData.self, forClassName: "Franziskianeum.VPlanDayData")
		NSKeyedUnarchiver.setClass(VPlanDayData.VPlanTableData.self, forClassName: "Franziskaneum.VPlanDayData.VPlanTableData")
		NSKeyedUnarchiver.setClass(VPlanDayData.VPlanTableData.self, forClassName: "VplanDayData.VplanTableData")
		
		if let vplan = NSKeyedUnarchiver.unarchiveObject(withFile: vplanURL.path) as? [VPlanDayData] {
			cachedVPlan = vplan
			completionHandler(vplan, .cache, nil)
		} else {
			completionHandler(nil, .cache, .fileNotFound)
		}
	}
	
	/**
	func authenticate(password: String, completionHandler: () -> Void) {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
	let authenticationSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
	let authenticationRequest = NSMutableURLRequest(URL: NSURL(string: "http://www.franziskaneum.de/wordpress/wp-login.php?action=postpass")!)
	authenticationRequest.HTTPShouldHandleCookies = false
	authenticationRequest.HTTPMethod = "POST"
	authenticationRequest.HTTPBody = "post_password=\(password)&Submit=Senden".dataUsingEncoding(NSUTF8StringEncoding)
	let authenticationTask = authenticationSession.dataTaskWithRequest(authenticationRequest, completionHandler: { (data: NSData?, response: NSURLResponse?, error: NSError?) in
	if let headerFields = (response as! NSHTTPURLResponse).allHeaderFields as? [String: String] {
	var cookies: String?
	
	for cookie in NSHTTPCookie.cookiesWithResponseHeaderFields(headerFields, forURL: (response?.URL)!) {
	if cookies == nil {
	cookies = String()
	}
	
	cookies! += "\(cookie.name)=\(cookie.value);"
	}
	
	let userDefaults = NSUserDefaults.standardUserDefaults()
	userDefaults.setObject(cookies, forKey: VPlanManager.KeyVPlanCookie)
	
	completionHandler()
	}
	})
	authenticationTask.resume()
	}
	}
	**/
	
	func authenticate(_ password: String, completionHandler: @escaping (_ authenticationSucceed: Bool) -> Void) {
		settings.setVPlanAuthenticationPassword(password)
		
		if let base64Login = base64Login {
			let vplanSession = URLSession(configuration: URLSessionConfiguration.default)
			var vplanRequest = URLRequest(url: URL(string: "http://www.franziskaneum.de/vplan/vplank.xml")!)
			vplanRequest.httpMethod = "HEAD"
			vplanRequest.addValue("Basic \(base64Login)", forHTTPHeaderField: "Authorization")
			let vplanTask = vplanSession.dataTask(with: vplanRequest, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
				if let response = response as? HTTPURLResponse {
					completionHandler(response.statusCode != 401)
				} else {
					completionHandler(false)
				}
			})
			vplanTask.resume()
		} else {
			completionHandler(false)
		}
	}
}
