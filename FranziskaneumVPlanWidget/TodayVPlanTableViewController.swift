//
//  TodayViewController.swift
//  FranziskaneumVPlanWidget
//
//  Created by Niko Kirste on 13.05.17.
//  Copyright © 2017 Franziskaneum. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayVPlanTableViewController: UIViewController, NCWidgetProviding, UITableViewDelegate, UITableViewDataSource {
	var notificationVPlan: [VPlanDayData]?
	var completionHandler: ((NCUpdateResult) -> Void)?
	
	@IBOutlet weak var label: UILabel!
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var labelHeightConstraint: NSLayoutConstraint!
	
	var vplanCompletionHandler: (([VPlanDayData]?, VPlanLoadingMode, FranziskaneumError?) -> Void)!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		vplanCompletionHandler = { (vplan, mode, error) in
			self.handleLoadingResult(vplan: vplan, mode: mode, error: error)
		}
		
		tableView.estimatedRowHeight = 26
		tableView.rowHeight = UITableViewAutomaticDimension
		tableView.estimatedSectionHeaderHeight = 26
		tableView.sectionHeaderHeight = UITableViewAutomaticDimension
	}
	
	override func viewWillAppear(_ animated: Bool) {
		SettingsManager.instance.refresh()
		VPlanManager.instance.getVPlan(.cache, completionHandler: vplanCompletionHandler)
		
		if #available(iOS 10.0, *) {
			if extensionContext!.widgetActiveDisplayMode == .compact {
				self.labelHeightConstraint.constant = extensionContext!.widgetMaximumSize(for: .compact).height
				self.label.alpha = 1.0
			} else {
				self.labelHeightConstraint.constant = 0
				self.label.alpha = 0.0
			}
		}
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		if #available(iOS 10.0, *) {
			if (extensionContext!.widgetActiveDisplayMode == .compact) {
				let maxSize = extensionContext!.widgetMaximumSize(for: .compact)
				
				if self.preferredContentSize.height != maxSize.height {
					self.preferredContentSize = maxSize
				}
			} else {
				DispatchQueue.main.async {
					let height = self.tableView.contentSize.height
					var contentSize = self.preferredContentSize
					var tableViewFrame = self.tableView.frame
					
					if height != tableViewFrame.size.height {
						contentSize.height = height
						self.preferredContentSize = contentSize
						
						tableViewFrame.size.height = height
						self.tableView.frame = tableViewFrame
					}
				}
			}
		}
	}
	
	func handleLoadingResult(vplan: [VPlanDayData]?, mode: VPlanLoadingMode, error: FranziskaneumError?) {
		if let vplan = vplan {
			var changesVPlan: [VPlanDayData] = [VPlanDayData]()
			
			for vplanDay in vplan {
				changesVPlan.append(vplanDay.copy() as! VPlanDayData)
			}
			
			let notificationManager = VPlanNotificationManager.instance
			
			notificationManager.removeOldDays(&changesVPlan)
			notificationManager.filterNotificationVPlan(&changesVPlan)
			
			self.notificationVPlan = changesVPlan
			
			DispatchQueue.main.async {
				self.tableView.reloadData()
				self.tableView.layoutIfNeeded()
				
				if let notificationVPlan = self.notificationVPlan, !notificationVPlan.isEmpty {
					var changesCount: Int = 0
					
					for vplanDay in notificationVPlan {
						changesCount += vplanDay.tableData?.count ?? 0
					}
					
					if notificationVPlan.count == 1 {
						self.label.text = "\(changesCount) Änderungen an einem Tag"
					} else {
						self.label.text = "\(changesCount) Änderungen an \(notificationVPlan.count) Tagen"
					}
					
					if #available(iOS 10.0, *) {
						self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
					}
				} else {
					self.label.text = "Keine Änderungen"
					
					if #available(iOS 10.0, *) {
						self.extensionContext?.widgetLargestAvailableDisplayMode = .compact
					}
				}
				
				if let completionHandler = self.completionHandler {
					completionHandler(.newData)
				}
			}
		}
	}
	
	@available(iOS 10.0, *)
	func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
		if activeDisplayMode == .compact {
			preferredContentSize = maxSize
		} else {
			self.preferredContentSize = self.tableView.contentSize
		}
	}
	
	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		coordinator.animate(alongsideTransition: { (context: UIViewControllerTransitionCoordinatorContext) in
			if #available(iOS 10.0, *) {
				let maxCompactSize = self.extensionContext!.widgetMaximumSize(for: .compact)
				
				if self.extensionContext!.widgetActiveDisplayMode == .expanded { // expanded
					self.labelHeightConstraint.constant = 0
					self.label.alpha = 0.0
				} else { // compact
					self.labelHeightConstraint.constant = maxCompactSize.height
					self.label.alpha = 1.0
				}
			}
		}, completion: nil)
	}
	
	func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
		self.completionHandler = completionHandler
		VPlanManager.instance.getVPlan(.ifModified, completionHandler: vplanCompletionHandler)
		
		// Perform any setup necessary in order to update the view.
		
		// If an error is encountered, use NCUpdateResult.Failed
		// If there's no update required, use NCUpdateResult.NoData
		// If there's an update, use NCUpdateResult.NewData
		
		// completionHandler(NCUpdateResult.newData)
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	// MARK: - Table view data source
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return self.notificationVPlan?.count ?? 0
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.notificationVPlan?[section].tableData?.count ?? 0
	}
	
	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let cellHeaderIdentifier = "TodayVPlanTableViewHeader"
		let cell = tableView.dequeueReusableCell(withIdentifier: cellHeaderIdentifier) as! TodayVPlanHeaderTableViewCell
		
		if let vplanDay = self.notificationVPlan?[section] {
			cell.title.text = vplanDay.title
		}
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cellRowIdentifier = "TodayVPlanTableViewCell"
		let cell = tableView.dequeueReusableCell(withIdentifier: cellRowIdentifier, for: indexPath) as! TodayVPlanTableViewCell
		
		if let tableData = self.notificationVPlan?[indexPath.section].tableData?[indexPath.row] {
			cell.label.text = tableData.string()
		}
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if let notificationVPlan = self.notificationVPlan, let title = notificationVPlan[indexPath.section].title, let path = title.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) {
			extensionContext?.open(URL(string: "franziskaneum://vplan/\(path)")!, completionHandler: nil)
		}
		
		tableView.deselectRow(at: indexPath, animated: true)
	}
	
}
