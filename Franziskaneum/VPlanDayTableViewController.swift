//
//  VPlanDayTableViewController.swift
//  Franziskaneum
//
//  Created by Niko Kirste on 08.01.16.
//  Copyright © 2016 Franziskaneum. All rights reserved.
//

import UIKit
import TTTAttributedLabel
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
	switch (lhs, rhs) {
	case let (l?, r?):
		return l < r
	case (nil, _?):
		return true
	default:
		return false
	}
}

fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
	switch (lhs, rhs) {
	case let (l?, r?):
		return l <= r
	default:
		return !(rhs < lhs)
	}
}


class VPlanDayTableViewController: UITableViewController, TTTAttributedLabelDelegate {
	
	// MARK: Properties
	
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var modifiedLabel: UILabel!
	@IBOutlet weak var headerView: UIView!
	@IBOutlet weak var footerView: UIView!
	
	var vplanDay: VPlanDayData?
	var headerInformation: [Int] = []
	
	var teacherList: [TeacherData]?
	
	var tableRowHeights: [Int:CGFloat] = [:]
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		if let vplanDay = vplanDay {
			if let _ = vplanDay.absentTeacher {
				headerInformation.append(0)
			}
			
			if let _ = vplanDay.absentClasses {
				headerInformation.append(1)
			}
			
			if let _ = vplanDay.notAvailableRooms {
				headerInformation.append(2)
			}
			
			if let _ = vplanDay.changesTeacher {
				headerInformation.append(3)
			}
			
			if let _ = vplanDay.changesClasses {
				headerInformation.append(4)
			}
			
			if let _ = vplanDay.changesSupervision {
				headerInformation.append(5)
			}
			
			if let _ = vplanDay.additionalInfo {
				headerInformation.append(6)
			}
			
			titleLabel.text = vplanDay.title
			modifiedLabel.text = vplanDay.modified
		}
		
		// load teacher to link
		TeacherManager.instance.getTeacherList(false) { (teacherList: [TeacherData]?, error: FranziskaneumError?) in
			DispatchQueue.main.async {
				if let teacherList = teacherList , error == nil {
					self.teacherList = teacherList
					self.tableView.reloadData()
				}
			}
		}
		
		self.tableView.estimatedRowHeight = 56.0
		
		if let headerView = headerView {
			headerView.setNeedsLayout()
			headerView.layoutIfNeeded()
			
			let headerHeight = headerView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
			var headerFrame = headerView.frame
			headerFrame.size.height = headerHeight
			headerView.frame = headerFrame
			
			tableView.tableHeaderView = headerView
		}
		
		if let footerView = footerView {
			footerView.setNeedsLayout()
			footerView.layoutIfNeeded()
			
			let footerHeight = footerView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
			var footerFrame = footerView.frame
			footerFrame.size.height = footerHeight
			footerView.frame = footerFrame
			
			tableView.tableFooterView = footerView
		}
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		// Dynamic sizing for the header view
		if let headerView = tableView.tableHeaderView {
			let height = headerView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
			var headerFrame = headerView.frame
			
			// If we don't have this check, viewDidLayoutSubviews() will get
			// repeatedly, causing the app to hang.
			if height != headerFrame.size.height {
				headerFrame.size.height = height
				headerView.frame = headerFrame
				tableView.tableHeaderView = headerView
			}
		}
		
		// Dynamic sizing for the footer view
		if let footerView = tableView.tableFooterView {
			let height = footerView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
			var footerFrame = footerView.frame
			
			// If we don't have this check, viewDidLayoutSubviews() will get
			// repeatedly, causing the app to hang.
			if height != footerFrame.size.height {
				footerFrame.size.height = height
				footerView.frame = footerFrame
				tableView.tableFooterView = footerView
			}
		}
	}
	
	/**
	func initViews(vplanDay: VPlanDayData) {
	if (vplanDay.title != nil) {
	titleLabel.text = vplanDay.title
	} else {
	titleLabel.hidden = true
	}
	
	if (vplanDay.absentTeacher != nil) {
	absentTeacherLabel.text = vplanDay.absentTeacher
	} else {
	absentTeacherContainer.hidden = true
	}
	
	if (vplanDay.absentClasses != nil) {
	absentClassesLabel.text = vplanDay.absentClasses
	} else {
	absentClassesContainer.hidden = true
	}
	
	if (vplanDay.notAvailableRooms != nil) {
	notAvailableRoomsLabel.text = vplanDay.notAvailableRooms
	} else {
	notAvailableRoomsContainer.hidden = true
	notAvailableRoomsContainerHeight.active = true
	notAvailableRoomsContainer.frame.size.height = 0
	}
	
	if (vplanDay.changesTeacher != nil) {
	changesTeacherLabel.text = vplanDay.changesTeacher
	} else {
	changesTeacherContainer.hidden = true
	}
	
	if (vplanDay.changesClasses != nil) {
	changesClassesLabel.text = vplanDay.changesClasses
	} else {
	changesClassesContainer.hidden = true
	}
	
	if (vplanDay.changesSupervision != nil) {
	changesSupervisionLabel.text = vplanDay.changesSupervision
	} else {
	changesSupervisionContainer.hidden = true
	}
	
	if (vplanDay.additionalInfo != nil) {
	additionalInfoLabel.text = vplanDay.additionalInfo
	} else {
	additionalInfoContainer.hidden = true
	}
	
	if (vplanDay.modified != nil) {
	modifiedLabel.text = vplanDay.modified
	} else {
	modifiedLabel.hidden = true
	}
	
	fixHeaderAndFooterHeight()
	
	self.tableView.reloadData()
	}
	
	func fixHeaderAndFooterHeight() {
	headerView.setNeedsLayout()
	headerView.layoutIfNeeded()
	let headerHeight = headerView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
	var headerFrame = headerView.frame
	headerFrame.size.height = headerHeight
	headerView.frame = headerFrame
	tableView.tableHeaderView = headerView
	
	footerView.setNeedsLayout()
	footerView.layoutIfNeeded()
	let footerHeight = footerView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
	var footerFrame = footerView.frame
	footerFrame.size.height = footerHeight
	footerView.frame = footerFrame
	tableView.tableFooterView = footerView
	
	tableView.beginUpdates()
	tableView.endUpdates()
	}
	**/
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		var number: Int = 0
		
		if let vplanDay = vplanDay {
			number += headerInformation.count
			
			if let tableData = vplanDay.tableData {
				number += tableData.count + 2
			}
		}
		
		return number
	}
	
	func firstTableRow() -> Int? {
		let row = headerInformation.count + 1
		if row < tableView(tableView, numberOfRowsInSection: 0) {
			return row
		} else {
			return nil
		}
	}
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		let horizontalSizeClass = self.view.traitCollection.horizontalSizeClass
		let verticalSizeClass = self.view.traitCollection.verticalSizeClass
		
		if (indexPath as NSIndexPath).row <= headerInformation.count {
			return UITableViewAutomaticDimension
		} else if (indexPath as NSIndexPath).row == headerInformation.count + 1 {
			return 36.0
		} else {
			if let rowHeight = tableRowHeights[(indexPath as NSIndexPath).row] {
				return rowHeight
			} else {
				let tableRow = vplanDay!.tableData![(indexPath as NSIndexPath).row - headerInformation.count - 2]
				let font = UIFont.systemFont(ofSize: 15.0)
				
				
				/**
				let label = UILabel(frame: CGRectMake(0.0, 0.0, 0.0, CGFloat.max))
				label.numberOfLines = 0
				label.lineBreakMode = NSLineBreakMode.ByWordWrapping
				label.font = font
				
				var frame = label.frame
				
				var schoolClassHeight: CGFloat = 0
				if let schoolClass = tableRow.schoolClass {
				frame.size.width = 50.0
				label.frame = frame
				label.text = schoolClass
				label.sizeToFit()
				schoolClassHeight = label.frame.height
				}
				
				var hourHeight: CGFloat = 0
				if let hour = tableRow.hour {
				frame.size.width = 54.0
				label.frame = frame
				label.text = hour
				label.sizeToFit()
				hourHeight = label.frame.height
				}
				
				var subjectHeight: CGFloat = 0
				if let subject = tableRow.subject {
				frame.size.width = 36.0
				label.frame = frame
				label.text = subject
				label.sizeToFit()
				subjectHeight = label.frame.height
				}
				
				var teacherHeight: CGFloat = 0
				if let teacher = tableRow.teacher {
				frame.size.width = 50.0
				label.frame = frame
				label.text = teacher
				label.sizeToFit()
				teacherHeight = label.frame.height
				}
				
				var roomHeight: CGFloat = 0
				if let room = tableRow.room {
				frame.size.width = 43.0
				label.frame = frame
				label.text = room
				label.sizeToFit()
				roomHeight = label.frame.height
				}
				
				var infoHeight: CGFloat = 0
				if let info = tableRow.info {
				frame.size.width = tableView.bounds.width - 255.0
				label.frame = frame
				label.text = info
				label.sizeToFit()
				infoHeight = label.frame.height
				}
				
				return max(schoolClassHeight, hourHeight, subjectHeight, teacherHeight, roomHeight, infoHeight, 18.0) + 2.0
				
				**/
				
				var schoolClassHeight: CGFloat = 0.0
				if let schoolClass = tableRow.schoolClass {
					let width: CGFloat
					
					if self.view.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClass.compact && self.view.traitCollection.verticalSizeClass == UIUserInterfaceSizeClass.regular {
						width = 50.0
					} else {
						width = 89.0
					}
					
					schoolClassHeight = NSString(string: schoolClass).boundingRect(with: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSFontAttributeName:font], context: nil).height
				}
				
				var hourHeight: CGFloat = 0.0
				if let hour = tableRow.hour {
					hourHeight = NSString(string: hour).boundingRect(with: CGSize(width: 54.0, height: CGFloat.greatestFiniteMagnitude), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSFontAttributeName:font], context: nil).height
				}
				
				var subjectHeight: CGFloat = 0.0
				if let subject = tableRow.subject {
					subjectHeight = NSString(string: subject).boundingRect(with: CGSize(width: 36.0, height: CGFloat.greatestFiniteMagnitude), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSFontAttributeName:font], context: nil).height
				}
				
				var teacherHeight: CGFloat = 0.0
				if let teacher = tableRow.teacher {
					teacherHeight = NSString(string: teacher).boundingRect(with: CGSize(width: 50.0, height: CGFloat.greatestFiniteMagnitude), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSFontAttributeName:font], context: nil).height
				}
				
				var roomHeight: CGFloat = 0.0
				if let room = tableRow.room {
					roomHeight = NSString(string: room).boundingRect(with: CGSize(width: 43.0, height: CGFloat.greatestFiniteMagnitude), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSFontAttributeName:font], context: nil).height
				}
				
				var infoHeight: CGFloat = 0.0
				if let info = tableRow.info {
					let infoWidth: CGFloat
					if horizontalSizeClass == UIUserInterfaceSizeClass.regular && verticalSizeClass == UIUserInterfaceSizeClass.regular {
						infoWidth = tableView.frame.width - 271.0
					} else {
						infoWidth = tableView.frame.width - 255.0
					}
					
					infoHeight =  NSString(string: info).boundingRect(with: CGSize(width: infoWidth, height:  CGFloat.greatestFiniteMagnitude), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSFontAttributeName:font], context: nil).height
				}
				
				let rowHeight = max(schoolClassHeight, hourHeight, subjectHeight, teacherHeight, roomHeight, infoHeight, 18.0) + 3.0
				
				tableRowHeights[(indexPath as NSIndexPath).row] = rowHeight
				
				return rowHeight
			}
		}
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell: UITableViewCell
		
		if (indexPath as NSIndexPath).row < headerInformation.count {
			switch headerInformation[(indexPath as NSIndexPath).row] {
			case 0, 1, 2, 3, 4:
				cell = tableView.dequeueReusableCell(withIdentifier: "VPlanDayHeaderLeftRightTableViewCell", for: indexPath)
				
				if let tableCell = cell as? VPlanDayHeaderLeftRightTableViewCell {
					
					switch headerInformation[(indexPath as NSIndexPath).row] {
					case 0:
						tableCell.nameLabel.text = "Abwesende Lehrer"
						tableCell.valueLabel.text = vplanDay?.absentTeacher
						break
					case 1:
						tableCell.nameLabel.text = "Abwesende Klassen"
						tableCell.valueLabel.text = vplanDay?.absentClasses
						break
					case 2:
						tableCell.nameLabel.text = "Nicht verfügbare Räume"
						tableCell.valueLabel.text = vplanDay?.notAvailableRooms
						break
					case 3:
						tableCell.nameLabel.text = "Lehrer mit Änderung"
						tableCell.valueLabel.text = vplanDay?.changesTeacher
						break
					case 4:
						tableCell.nameLabel.text = "Klassen mit Änderung"
						tableCell.valueLabel.text = vplanDay?.changesClasses
						break
					default:
						break
					}
					
				}
				
				break
			default:
				cell = tableView.dequeueReusableCell(withIdentifier: "VPlanDayHeaderTopBottomTableViewCell", for: indexPath)
				
				if let tableCell = cell as? VPlanDayHeaderTopBottomTableViewCell {
					switch headerInformation[(indexPath as NSIndexPath).row] {
					case 5:
						tableCell.nameLabel.text = "Geänderte Aufsichten"
						tableCell.valueLabel.text = vplanDay?.changesSupervision
						break
					case 6:
						tableCell.nameLabel.text = "Zusätzliche Informationen"
						tableCell.valueLabel.text = vplanDay?.additionalInfo
						break
					default:
						break
					}
				}
				
				break
			}
		} else if (indexPath as NSIndexPath).row == headerInformation.count {
			cell = tableView.dequeueReusableCell(withIdentifier: "VPlanDayHeaderChangedLessonsTableViewCell", for: indexPath)
		} else if (indexPath as NSIndexPath).row == headerInformation.count + 1 {
			cell = tableView.dequeueReusableCell(withIdentifier: "VPlanDayTableHeaderTableViewCell", for: indexPath)
		} else {
			cell = tableView.dequeueReusableCell(withIdentifier: "VPlanDayTableViewCell", for: indexPath)
		}
		
		return cell
	}
	
	override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		if (indexPath as NSIndexPath).row > headerInformation.count {
			let lightGrayColor = UIColor.lightGray
			
			for subview in cell.subviews[0].subviews {
				subview.layer.borderWidth = 1.0
				subview.layer.borderColor = lightGrayColor.cgColor
			}
			
			if (indexPath as NSIndexPath).row > headerInformation.count + 1 {
				let tableCell = cell as! VPlanDayTableViewCell
				
				let tableRow = vplanDay!.tableData![(indexPath as NSIndexPath).row - headerInformation.count - 2]
				
				tableCell.schoolClassLabel.text = tableRow.schoolClass
				tableCell.hourLabel.text = tableRow.hour
				tableCell.subjectLabel.text = tableRow.subject
				tableCell.teacherLabel.text = tableRow.teacher
				tableCell.roomLabel.text = tableRow.room
				tableCell.infoLabel.text = tableRow.info
				
				// link teacher to [TeacherDetailViewController]
				
				let linkColor = UIColor(red: 162.0/255.0, green: 14.0/255.0, blue: 12.0/255.0, alpha: 1.0)
				let activeLinkColor = linkColor.withAlphaComponent(0.5)
				
				let linkAttributes = [NSForegroundColorAttributeName: linkColor, NSUnderlineStyleAttributeName: NSNumber(value: NSUnderlineStyle.styleSingle.rawValue)]
				let activeLinkAttributes = [NSForegroundColorAttributeName: activeLinkColor, NSUnderlineStyleAttributeName: NSNumber(value: NSUnderlineStyle.styleSingle.rawValue)]
				
				tableCell.teacherLabel.linkAttributes = linkAttributes
				tableCell.teacherLabel.activeLinkAttributes = activeLinkAttributes
				
				tableCell.infoLabel.linkAttributes = linkAttributes
				tableCell.infoLabel.activeLinkAttributes = activeLinkAttributes
				
				tableCell.teacherLabel.isUserInteractionEnabled = true
				tableCell.infoLabel.isUserInteractionEnabled = true
				
				if let teacherList = teacherList {
					DispatchQueue.global(qos: .default).async {
						for teacher in teacherList {
							if let range = teacher.nsRangeOfShortcutInString(tableCell.teacherLabel.text as NSString?) {
								DispatchQueue.main.async {
									if let tableCell = tableView.cellForRow(at: indexPath) as? VPlanDayTableViewCell, (range.location >= 0 && range.location + range.length <= tableCell.teacherLabel.text?.length) {
										// use an address to pass teacher rather than an url ;)
										tableCell.teacherLabel.addLink(toAddress: ["teacherData": teacher], with: range)
									}
									
									/**
									let newIndexPath = tableView.indexPath(for: tableCell)
									if (newIndexPath == nil || (indexPath as NSIndexPath).row == (newIndexPath! as NSIndexPath).row) && (range.location >= 0 && range.location + range.length <= tableCell.teacherLabel.text?.length) {
									// use an address to pass teacher rather than an url ;)
									tableCell.teacherLabel.addLink(toAddress: ["teacherData": teacher], with: range)
									}
									**/
								}
							}
							
							if let range = teacher.nsRangeOfShortcutInString(tableCell.infoLabel.text as NSString?) , range.location >= 0 && range.location + range.length <= tableCell.infoLabel.text?.length {
								DispatchQueue.main.async {
									if let tableCell = tableView.cellForRow(at: indexPath) as? VPlanDayTableViewCell, (range.location >= 0 && range.location + range.length <= tableCell.infoLabel.text?.length) {
										// use an address to pass teacher rather than an url ;)
										tableCell.infoLabel.addLink(toAddress: ["teacherData": teacher], with: range)
									}
									
									/**
									let newIndexPath = tableView.indexPath(for: tableCell)
									if (newIndexPath == nil || (indexPath as NSIndexPath).row == (newIndexPath! as NSIndexPath).row) && (range.location >= 0 && range.location + range.length <= tableCell.infoLabel.text?.length) {
									tableCell.infoLabel.addLink(toAddress: ["teacherData": teacher], with: range)
									}
									**/
								}
							}
						}
					}
				}
			}
		}
	}
	
	func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWithAddress addressComponents: [AnyHashable : Any]!) {
		if let teacher = addressComponents["teacherData"] as? TeacherData {
			let teacherDetailViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TeacherDetailTableViewController") as! TeacherDetailTableViewController
			
			teacherDetailViewController.teacher = teacher
			teacherDetailViewController.navigationItem.title = teacher.name
			
			navigationController?.pushViewController(teacherDetailViewController, animated: true)
		}
	}
	
}
