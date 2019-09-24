//
//  TeacherTableViewController.swift
//  Franziskaneum
//
//  Created by Niko Kirste on 19.01.16.
//  Copyright © 2016 Franziskaneum. All rights reserved.
//

import UIKit

class TeacherTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
	
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var searchBar: UISearchBar!
	@IBOutlet weak var navHairlineConstraint: NSLayoutConstraint!
	@IBOutlet weak var searchViewTopConstraint: NSLayoutConstraint!
	
	let teacherManager = TeacherManager.instance
	var teacherList: [TeacherData]?
	var filteredTeacherList: [TeacherData] = []
	
	var activityIndicatorView: UIActivityIndicatorView!
	var refreshControl: UIRefreshControl!
	var navHairlineImageView: UIImageView?
	
	var completionHandler: ((_ teacherList: [TeacherData]?, _ error: FranziskaneumError?) -> Void)!
	
	var isSearching: Bool = false
	var displaySearchResults = false
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.refreshControl = UIRefreshControl()
		self.refreshControl?.addTarget(self, action: #selector(self.handleRefresh), for: UIControlEvents.valueChanged)
		self.refreshControl.tintColor = UIColor.franziskaneum
		self.tableView.addSubview(refreshControl)
		
		completionHandler = { (teacherList, error) in
			DispatchQueue.main.async {
				self.handleLoadingResult(teacherList, error: error)
			}
		}
		
		activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
		activityIndicatorView.color = UIColor.franziskaneum
		tableView.backgroundView = activityIndicatorView
		activityIndicatorView.hidesWhenStopped = true
		
		let adjustForTabbarInsets: UIEdgeInsets = UIEdgeInsetsMake(0, 0, self.tabBarController!.tabBar.frame.height, 0);
		//Where tableview is the IBOutlet for your storyboard tableview.
		self.tableView.contentInset = adjustForTabbarInsets;
		self.tableView.scrollIndicatorInsets = adjustForTabbarInsets;
		
		searchBar.enablesReturnKeyAutomatically = false
		
		// modify the hairline image ;)
		navHairlineImageView = findHairlineImageViewUnder(navigationController!.navigationBar)
		navHairlineConstraint.constant = 0.5
		
		searchViewTopConstraint.constant = -searchBar.frame.height
		searchBar.alpha = 0.0
	}
	
	override func viewWillAppear(_ animated: Bool) {
		self.navHairlineImageView?.isHidden = true
		
		if teacherList == nil {
			startRefreshing()
			teacherManager.getTeacherList(false, completionHandler: completionHandler)
		}
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(150 * Double(NSEC_PER_MSEC))) / Double(NSEC_PER_SEC)) {
			self.navHairlineImageView?.isHidden = false
		}
	}
	
	func findHairlineImageViewUnder(_ view: UIView) -> UIImageView? {
		if view is UIImageView && view.bounds.size.height <= 1.0 {
			return view as? UIImageView
		}
		for subView in view.subviews {
			if let imageView = findHairlineImageViewUnder(subView) {
				return imageView
			}
		}
		
		return nil
	}
	
	func startRefreshing() {
		if let teacherList = teacherList, !teacherList.isEmpty {
			refreshControl?.beginRefreshing()
		} else {
			activityIndicatorView.startAnimating()
		}
	}
	
	func stopRefreshing() {
		refreshControl?.endRefreshing()
		activityIndicatorView.stopAnimating()
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	
	// called when the user pulls the list to refresh
	func handleRefresh() {
		teacherManager.getTeacherList(true, completionHandler: completionHandler)
	}
	
	func handleLoadingResult(_ teacherList: [TeacherData]?, error: FranziskaneumError?) {
		stopRefreshing()
		
		if let teacherList = teacherList {
			self.teacherList = teacherList
			self.tableView.reloadData()
		} else if let error = error {
			if error == FranziskaneumError.fileNotFound {
				startRefreshing()
				teacherManager.getTeacherList(true, completionHandler: completionHandler)
			} else {
				if self.isVisible {
					let message = error.description()
					
					// alert the user
					let alert = UIAlertController(title: "Fehler", message: message, preferredStyle: .alert)
					alert.view.tintColor = UIColor.franziskaneum
					alert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel, handler: nil))
					alert.addAction(UIAlertAction(title: "Erneut Versuchen", style: .default, handler: { (action: UIAlertAction) in
						self.teacherManager.getTeacherList(true, completionHandler: self.completionHandler)
						self.startRefreshing()
					}))
					
					// needs to be called otherwise warning
					alert.view.setNeedsLayout()
					self.present(alert, animated: true, completion: nil)
				}
			}
		}
	}
	
	func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
		print("search: \(searchText)")
		
		if searchText.isEmpty {
			displaySearchResults = false
		} else if let teacherList = teacherList {
			let lowerCaseSearchText = searchText.lowercased()
			
			self.filteredTeacherList = teacherList.filter({ (teacher: TeacherData) in
				return teacher.string().lowercased().range(of: lowerCaseSearchText) != nil
			})
			
			displaySearchResults = true
		}
		
		tableView.reloadData()
	}
	
	func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
		searchBar.resignFirstResponder()
	}
	
	@IBAction func searchButtonClicked(_ sender: UIBarButtonItem) {
		isSearching = !isSearching
		
		if isSearching {
			searchViewTopConstraint.constant = 0.0
			
			UIView.animate(withDuration: 0.3) {
				self.view.layoutIfNeeded()
				self.searchBar.alpha = 1.0
			}
			
			searchBar.becomeFirstResponder()
		} else {
			searchViewTopConstraint.constant = -searchBar.frame.height
			
			UIView.animate(withDuration: 0.3) {
				self.view.layoutIfNeeded()
				self.searchBar.alpha = 0.0
			}
			
			searchBar.resignFirstResponder()
		}
		
		if filteredTeacherList.count != teacherList?.count {
			let indexSet = NSIndexSet(index: 0)
			self.tableView.reloadSections(indexSet as IndexSet, with: .fade)
		}
	}
	
	// MARK: - Table view data source
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if isSearching && displaySearchResults {
			return filteredTeacherList.count
		} else {
			return teacherList?.count ?? 0
		}
	}
	
	func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
		return 64.0
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let teacher: TeacherData!
		
		if isSearching && displaySearchResults {
			teacher = filteredTeacherList[indexPath.row]
		} else {
			teacher = teacherList![indexPath.row]
		}
		
		let cell = tableView.dequeueReusableCell(withIdentifier: "TeacherTableViewCell", for: indexPath) as! TeacherTableViewCell
		
		cell.nameLabel.text = "\(teacher.forename!) \(teacher.name!)"
		cell.subjectsLabel.text = teacher.subjects
		cell.shortcutLabel.text = teacher.shortcut
		
		cell.makeCircleAroundLabel()
		cell.setCircleBackgroundColor(TeacherData.getColorForTeacher(teacher))
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return false
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
	}
	
	/*
	// Override to support conditional editing of the table view.
	override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
	// Return false if you do not want the specified item to be editable.
	return true
	}
	*/
	
	/*
	// Override to support editing the table view.
	override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
	if editingStyle == .Delete {
	// Delete the row from the data source
	tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
	} else if editingStyle == .Insert {
	// Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
	}
	}
	*/
	
	/*
	// Override to support rearranging the table view.
	override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
	
	}
	*/
	
	/*
	// Override to support conditional rearranging of the table view.
	override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
	// Return false if you do not want the item to be re-orderable.
	return true
	}
	*/
	
	// MARK: - Navigation
	
	// In a storyboard-based application, you will often want to do a little preparation before navigation
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		let detailViewController = segue.destination as! TeacherDetailTableViewController
		
		if let selectedCell = sender as? TeacherTableViewCell {
			let indexPath = self.tableView.indexPath(for: selectedCell)!
			let teacher: TeacherData!
			
			if isSearching && displaySearchResults {
				teacher = filteredTeacherList[indexPath.row]
			} else {
				teacher = teacherList![indexPath.row]
			}
			
			detailViewController.teacher = teacher
			detailViewController.navigationItem.title = teacher.name
		}
	}
	
}
