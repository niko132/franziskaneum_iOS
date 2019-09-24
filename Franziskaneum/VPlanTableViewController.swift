//
//  VPlanTableViewController.swift
//  Franziskaneum
//
//  Created by Niko Kirste on 04.01.16.
//  Copyright © 2016 Franziskaneum. All rights reserved.
//

import UIKit

class VPlanTableViewController: UITableViewController {
	
	@IBOutlet weak var testLabel: UILabel!
	
	var vplanManager = VPlanManager.instance
	var vplan: [VPlanDayData]?
	var changesVPlan: [VPlanDayData]?
	
	var activityIndicatorView: UIActivityIndicatorView!
	
	var completionHandler: (([VPlanDayData]?, VPlanLoadingMode, FranziskaneumError?) -> Void)!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.rowHeight = UITableViewAutomaticDimension
		
		refreshControl?.addTarget(self, action: #selector(VPlanTableViewController.handleRefresh), for: .valueChanged)
		
		completionHandler = { (vplan, mode, error) in
			DispatchQueue.main.async {
				self.handleLoadingResult(vplan: vplan, mode: mode, error: error)
			}
		}
		
		activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
		activityIndicatorView.color = UIColor.franziskaneum
		tableView.backgroundView = activityIndicatorView
		activityIndicatorView.hidesWhenStopped = true
		
		startRefreshing()
		vplanManager.getVPlan(.cache, completionHandler: completionHandler)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		getChangesVPlan()
		
		if vplan == nil {
			startRefreshing()
			vplanManager.getVPlan(.cache, completionHandler: completionHandler)
		} else {
			vplanManager.getVPlan(.ifModified, completionHandler: completionHandler)
		}
	}
	
	func handleRefresh() {
		vplanManager.getVPlan(.download, completionHandler: completionHandler)
	}
	
	func startRefreshing() {
		if let vplan = vplan, !vplan.isEmpty {
			refreshControl?.beginRefreshing()
		} else {
			activityIndicatorView.startAnimating()
		}
	}
	
	func stopRefreshing() {
		refreshControl?.endRefreshing()
		activityIndicatorView.stopAnimating()
	}
	
	func handleLoadingResult(vplan: [VPlanDayData]?, mode: VPlanLoadingMode, error: FranziskaneumError?) {		
		if let vplan = vplan, mode == .cache, self.vplan == nil {
			stopRefreshing()
			self.vplan = vplan
			getChangesVPlan()
			
			vplanManager.getVPlan(.ifModified, completionHandler: completionHandler)
			startRefreshing()
		} else {
			if let vplan = vplan {
				self.vplan = vplan
				getChangesVPlan()
				stopRefreshing()
			} else if let error = error {
				if error == .authenticationFailed {
					authenticationNeeded(false)
				} else if error == .fileNotFound {
					vplanManager.getVPlan(.download, completionHandler: completionHandler)
				} else {
					if self.isVisible {
						let message = error.description()
						
						// alert the user
						let alertController = UIAlertController(title: "Fehler", message: message, preferredStyle: .alert)
						alertController.view.tintColor = UIColor.franziskaneum
						alertController.addAction(UIAlertAction(title: "Abbrechen", style: .cancel, handler: nil))
						alertController.addAction(UIAlertAction(title: "Erneut Versuchen", style: .default, handler: { (action: UIAlertAction) in
							self.vplanManager.getVPlan(.ifModified, completionHandler: self.completionHandler)
						}))
						
						// needs to be called otherwise warning
						alertController.view.setNeedsLayout()
						self.present(alertController, animated: true, completion: nil)
					}
				}

			}
		}
	}
	
	func getChangesVPlan() {
		if let vplan = vplan {
			changesVPlan = [VPlanDayData]()
			for vplanDay in vplan {
				changesVPlan?.append(vplanDay.copy() as! VPlanDayData)
			}
			VPlanNotificationManager.instance.filterNotificationVPlan(&changesVPlan!)
			tableView.reloadData()
		}
	}
	
	func authenticationNeeded(_ didEnterWrongPassword: Bool) {
		let message: String
		
		if didEnterWrongPassword {
			message = "Falsches Passwort"
		} else {
			message = "Dieser Inhalt ist passwortgeschützt. Um ihn anzuschauen, gib bitte dein Passwort ein"
		}
		
		let passwordAlert = UIAlertController(title: "Passwort", message: message, preferredStyle: UIAlertControllerStyle.alert)
		passwordAlert.view.tintColor = UIColor.franziskaneum
		passwordAlert.addAction(UIAlertAction(title: "Senden", style: UIAlertActionStyle.default, handler: { (_) in
			let passwordTextView = passwordAlert.textFields![0]
			
			print("Authenticate with \"\(passwordTextView.text)\"", terminator: "")
			
			self.vplanManager.authenticate(passwordTextView.text!) { (authenticationSuceed: Bool) in
				if authenticationSuceed {
					self.vplanManager.getVPlan(.ifModified, completionHandler: self.completionHandler)
					
					(UIApplication.shared.delegate as! AppDelegate).connectToFcm()
				} else {
					self.authenticationNeeded(true)
				}
			}
		}))
		
		passwordAlert.addAction(UIAlertAction(title: "Abbrechen", style: UIAlertActionStyle.cancel, handler: { (_) in
			
		}))
		
		passwordAlert.addTextField(configurationHandler: { (textField: UITextField) in
			textField.placeholder = "Passwort"
			textField.isSecureTextEntry = true
		})
		
		// needs to be called otherwise warning
		passwordAlert.view.setNeedsLayout()
		self.present(passwordAlert, animated: true, completion: nil)
	}
	
	// MARK: - Table view data source
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return vplan?.count ?? 0
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		// Table view cells are reused and should be dequeued using a cell identifier.
		let cellIdentifier = "VPlanTableViewCell"
		
		let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! VPlanTableViewCell
		
		let vplanDay = vplan![(indexPath as NSIndexPath).row]
		var changesVPlanDay: VPlanDayData?
		
		if let vplan = changesVPlan {
			for day in vplan {
				if day.title == vplanDay.title {
					changesVPlanDay = day
				}
			}
		}
		
		cell.titleLabel.text = vplanDay.title
		
		if let changesVPlanDay = changesVPlanDay, let changesVPlanDayTable = changesVPlanDay.tableData , !changesVPlanDayTable.isEmpty {
			cell.subtitleLabel.text = "\(changesVPlanDayTable.count) Änderungen"
			cell.subtitleLabel.textColor = UIColor(red: 162.0/255.0, green: 14.0/255.0, blue: 12.0/255.0, alpha: 1.0)
		} else {
			cell.subtitleLabel.text = vplanDay.modified
			cell.subtitleLabel.textColor = UIColor.darkGray
		}
		
		return cell
	}
	
	override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
		return UITableViewAutomaticDimension
	}
	
	override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return false
	}
	
	// MARK: Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		let vplanDayControlViewController = segue.destination as! VPlanDayControlViewController
		
		if let selectedCell = sender as? VPlanTableViewCell {
			let indexPath = self.tableView.indexPath(for: selectedCell)!
			let vplanDay = vplan![(indexPath as NSIndexPath).row]
			vplanDayControlViewController.generalVPlanDay = vplanDay
			vplanDayControlViewController.title = vplanDay.getNameOfDay()
		}
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	
}
