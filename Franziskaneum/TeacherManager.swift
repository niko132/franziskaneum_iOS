//
//  TeacherManager.swift
//  Franziskaneum
//
//  Created by Niko Kirste on 19.01.16.
//  Copyright © 2016 Franziskaneum. All rights reserved.
//

import Foundation

class TeacherManager {
    
    // MARK: Properties
    let fileTeacherList = "teacherList"
    
    static let instance = TeacherManager()
    
    // MARK: Archiving Paths
	let teacherListURL: URL!
    
    fileprivate var teacherList: [TeacherData]?
    
    fileprivate init() {
		let fileManager = FileManager.default
		
		var teacherListURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.de.franziskaneum.Franziskaneum")?.appendingPathComponent(fileTeacherList)
		let oldTeacherListURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileTeacherList)
		
		if let teacherListURL = teacherListURL {
			if let oldURL = oldTeacherListURL, fileManager.fileExists(atPath: oldURL.path) {
				do {
					try fileManager.moveItem(at: oldURL, to: teacherListURL)
				} catch {}
			}
		} else {
			teacherListURL = oldTeacherListURL
		}
		
		self.teacherListURL = teacherListURL
    }
    
    func getTeacherList(_ refresh: Bool, completionHandler: ((_ teacherList: [TeacherData]?, _ error: FranziskaneumError?) -> Void)?) {
        if let teacherList = teacherList , !refresh {
            if let completionHandler = completionHandler {
                completionHandler(teacherList, nil)
            }
        } else {
            DispatchQueue.global(qos: .default).async {
                if refresh {
                    self.downloadTeacherListData() { (data: Data?, error: FranziskaneumError?) in
                        if let data = data {
                            let returnValue = self.parseTeacherListWithData(data)
                            
                            if let teacherList = returnValue.teacherList {
                                self.teacherList = teacherList
                                self.saveTeacherList(teacherList)
                                
                                if let completionHandler = completionHandler {
                                    completionHandler(teacherList, nil)
                                }
                            } else if let error = returnValue.error, let completionHandler = completionHandler {
                                completionHandler(nil, error)
                            } else if let completionHandler = completionHandler {
                                completionHandler(nil, .unknownError)
                            }
                        } else if let error = error, let completionHandler = completionHandler {
                            completionHandler(nil, error)
                        } else if let completionHandler = completionHandler {
                            completionHandler(nil, .unknownError)
                        }
                    }
                } else {
                    let returnValue = self.loadTeacherList()
                    
                    if let teacherList = returnValue.teacherList {
                        self.teacherList = teacherList
                        
                        if let completionHandler = completionHandler {
                            completionHandler(teacherList, nil)
                        }
                    } else if let error = returnValue.error, let completionHandler = completionHandler {
                        completionHandler(nil, error)
                    } else if let completionHandler = completionHandler {
                        completionHandler(nil, .unknownError)
                    }
                }
            }
        }
    }
    
    func loadTeacherList() -> (teacherList: [TeacherData]?, error: FranziskaneumError?) {
		NSKeyedUnarchiver.setClass(TeacherData.self, forClassName: "TeacherData")
		NSKeyedUnarchiver.setClass(TeacherData.self, forClassName: "Franziskaneum.TeacherData")
        if let teacherList = NSKeyedUnarchiver.unarchiveObject(withFile: teacherListURL.path) as? [TeacherData] {
            return (teacherList, nil)
        } else {
            return (nil, .fileNotFound)
        }
    }
    
    func downloadTeacherListData(_ completionHandler: @escaping (_ data: Data?, _ error: FranziskaneumError?) -> Void) {
        let teacherSession = URLSession(configuration: URLSessionConfiguration.default)
        let teacherRequest = URLRequest(url: URL(string: "http://www.franziskaneum.de/wordpress/wer-wir-sind/lehrerliste/")!)
        
        let teacherTask = teacherSession.dataTask(with: teacherRequest, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if let data = data {
                completionHandler(data, nil)
            } else {
                completionHandler(nil, .networkError)
            }
        })
        teacherTask.resume()
    }
    
    func parseTeacherListWithData(_ data: Data) -> (teacherList: [TeacherData]?, error: FranziskaneumError?) {
        let parser = TFHpple(data: data, isXML: false)
        
        var teacherList: [TeacherData]?
        
        if let tableElement = (parser?.search(withXPathQuery: "//tbody") as! [TFHppleElement]).first {
            teacherList = [TeacherData]()
            
            var teacherElements = tableElement.search(withXPathQuery: "//tr") as![TFHppleElement]
            if teacherElements.count > 0 {
                teacherElements.remove(at: 0)
                
                for teacherElement in teacherElements {
                    let teacherData = TeacherData()
                    
                    let tds = teacherElement.search(withXPathQuery: "//td") as! [TFHppleElement]
                    if tds.count > 3 {
                        teacherData.shortcut = tds[0].content.trim()
                        
                        let names = tds[1].content.trim()
                        
                        if names.contains(",") {
                            let splittedNames = names.components(separatedBy: ",")
                            if splittedNames.count > 1 {
                                teacherData.name = splittedNames[0].trim().removeNewline()
                                teacherData.forename = splittedNames[1].trim().removeNewline()
                            }
                        } else if names.contains(" ") {
                            let splittedNames = names.components(separatedBy: " ")
                            if splittedNames.count > 1{
                                teacherData.name = splittedNames[0].trim().removeNewline()
                                teacherData.forename = splittedNames[1].trim().removeNewline()
                            }
                        } else {
                            teacherData.name = names
                        }
                        
                        teacherData.subjects = tds[2].content.trim()
                        teacherData.specificTasks = tds[3].content.trim()
                        
                        teacherList!.append(teacherData)
                    }
                }
            }
        }
        
        if teacherList == nil || teacherList!.count == 0 {
            return (nil, .unknownError)
        }
        
        return (teacherList, nil)
    }
    
    func saveTeacherList(_ teacherList: [TeacherData]) {
        DispatchQueue.global(qos: .default).async {
			NSKeyedArchiver.setClassName("TeacherData", for: TeacherData.self)
            NSKeyedArchiver.archiveRootObject(teacherList, toFile: self.teacherListURL.path)
        }
    }
    
}
