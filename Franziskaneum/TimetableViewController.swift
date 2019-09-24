//
//  TimetableViewController.swift
//  Franziskaneum
//
//  Created by Niko Kirste on 14.01.16.
//  Copyright © 2016 Franziskaneum. All rights reserved.
//

import UIKit

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

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class TimetableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: Properties
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var daySegmentedControl: UISegmentedControl!
    @IBOutlet weak var navHairlineConstraint: NSLayoutConstraint!
    @IBOutlet weak var toolbarView: UIToolbar!
    @IBOutlet weak var copieWeekItem: UIBarButtonItem!
    @IBOutlet weak var deleteItem: UIBarButtonItem!
    @IBOutlet weak var toolbarHairlineConstraint: NSLayoutConstraint!
    @IBOutlet weak var toolbarContainerView: UIView!
    
    let allTimes: [[[String]]] = [
        [
            ["7:30", "8:15"],
            ["8:25", "9:10"],
            ["9:25", "10:10"],
            ["10:10", "10:55"],
            ["11:15", "12:00"],
            ["12:40", "13:25"],
            ["13:35", "14:20"],
            ["14:30", "15:15"],
            ["15:15", "16:00"]],
        [
            ["7:30", "8:15"],
            ["8:25", "9:10"],
            ["9:25", "10:10"],
            ["10:10", "10:55"],
            ["11:15", "12:00"],
            ["12:10", "12:55"],
            ["13:35", "14:20"],
            ["14:30", "15:15"],
            ["15:15", "16:00"]
        ]
    ]
    
    var weekSegmentedControl: UISegmentedControl!
    
    let settings = SettingsManager.instance
    
    var timetableManager: TimetableManager!
    var timetable: [[[TimetableData]]]?
    
    var week = 0, day = 0
    var showTimes = false
    
    var navHairlineImageView: UIImageView?
    
    var completionHandler: ((_ timetable: [[[TimetableData]]]) -> Void)!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        weekSegmentedControl = UISegmentedControl(items: ["Woche A", "Woche B"])
        weekSegmentedControl.sizeToFit()
        weekSegmentedControl.selectedSegmentIndex = week
        weekSegmentedControl.addTarget(self, action: #selector(self.weekSegmentSelected), for: .valueChanged)
        
        timetableManager = TimetableManager.instance
        
        completionHandler = { (timetable) in
            DispatchQueue.main.async {
                self.handleLoadingResult(timetable)
            }
        }
        
        timetableManager.getTimetable(completionHandler)
        
        // modify the hairline image ;)
        navHairlineImageView = findHairlineImageViewUnder(navigationController!.navigationBar)
        navHairlineConstraint.constant = 0.5
        toolbarHairlineConstraint.constant = 0.5
        
        navigationController?.view.backgroundColor = UIColor.white
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navHairlineImageView?.isHidden = true
        
        if !self.settings.hasABWeek {
            self.weekSegmentedControl.selectedSegmentIndex = 0
            self.weekSegmentSelected(self.weekSegmentedControl)
            self.navigationItem.titleView = nil
            self.navigationItem.title = "Stundenplan"
        } else {
            self.navigationItem.title = nil
            self.navigationItem.titleView = self.weekSegmentedControl
        }
        
        toolbarContainerView.frame = toolbarContainerView.frame.offsetBy(dx: 0.0, dy: self.toolbarContainerView.frame.height)
        UIView.animate(withDuration: 0.3, animations: {
            self.toolbarContainerView.frame = self.toolbarContainerView.frame.offsetBy(dx: 0.0, dy: -self.toolbarContainerView.frame.height)
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(150 * Double(NSEC_PER_MSEC))) / Double(NSEC_PER_SEC)) {
            self.navHairlineImageView?.isHidden = false
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func handleLoadingResult(_ timetable: [[[TimetableData]]]) {
        self.timetable = timetable
        self.tableView.reloadData()
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
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return timetable?[week][day].count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let subject = timetable![week][day][(indexPath as NSIndexPath).section]
        
        if subject.isDoubleHour! {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TimetableDoubleHourTableViewCell", for: indexPath) as! TimetableDoubleHourTableViewCell
            
            cell.contentView.layoutIfNeeded()
            cell.timesViewLeadingConstraint.constant = showTimes ? 0 : -50
            UIView.animate(withDuration: 0.5, animations: {
                cell.contentView.layoutIfNeeded()
                cell.timesView.alpha = self.showTimes ? 1.0 : 0.0
            })
            
            var times: [[String]]! = nil
            
            if settings.isTeacher {
                if let schoolClass = subject.subject , !schoolClass.isEmpty {
                    if schoolClass.contains("/") {
                        let schoolClassStepString = (schoolClass as NSString).substring(to: schoolClass.indexOf("/"))
                        if let schoolClassStep = Int(schoolClassStepString) {
                            times = schoolClassStep >= 5 && schoolClassStep < 7 ? allTimes[0] : allTimes[1]
                        }
                    }
                    
                    if schoolClass.contains(" ") {
                        let schoolClassStepString = (schoolClass as NSString).substring(to: schoolClass.indexOf(" "))
                        if let schoolClassStep = Int(schoolClassStepString) {
                            times = schoolClassStep >= 5 && schoolClassStep < 7 ? allTimes[0] : allTimes[1]
                        }
                    }
                }
                
                if times == nil {
                    times = allTimes[1]
                }
            } else {
                times = settings.schoolClassStep < 7 ? allTimes[0] : allTimes[1]
            }
            
            if let times = times {
                let hourIndex: Int
                if let timetable = timetable {
                    hourIndex = TimetableData.getHourForIndex(timetable[week][day], subjectIndex: (indexPath as NSIndexPath).section) - 1
                } else {
                    if let hour = subject.hour {
                        hourIndex = hour - 1
                    } else {
                        hourIndex = -1
                    }
                }
                
                if hourIndex >= 0 && hourIndex + 1 < times.count {
                    let subjectTimes1: [String] = times[hourIndex]
                    let subjectTimes2: [String] = times[hourIndex + 1]
                    cell.startTimeLabel.text = subjectTimes1[0]
                    cell.endTimeLabel.text = subjectTimes2[1]
                } else {
                    cell.startTimeLabel.text = ""
                    cell.endTimeLabel.text = ""
                }
            }
            
            cell.firstHourLabel.text = "\(subject.hour!)."
            cell.secondHourLabel.text = "\(subject.hour! + 1)."
            cell.roomLabel.text = subject.room!
            cell.teacherOrSchoolClassLabel.text = subject.teacherOrSchoolClass!
            
            if let subject = subject.subject , !subject.isEmpty {
                cell.subjectLabel.text = subject
            } else {
                cell.subjectLabel.text = "[ Freistunde ]"
            }
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TimetableSingleHourTableViewCell", for: indexPath) as! TimetableSingleHourTableViewCell
            
            cell.contentView.layoutIfNeeded()
            cell.timesViewLeadingConstraint.constant = showTimes ? 0 : -50
            UIView.animate(withDuration: 0.5, animations: {
                cell.contentView.layoutIfNeeded()
                cell.timesView.alpha = self.showTimes ? 1.0 : 0.0
            })
            
            var times: [[String]]! = nil
            
            if settings.isTeacher {
                if let schoolClass = subject.subject , !schoolClass.isEmpty {
                    if schoolClass.contains("/") {
                        let schoolClassStepString = (schoolClass as NSString).substring(to: schoolClass.indexOf("/"))
                        if let schoolClassStep = Int(schoolClassStepString) {
                            times = schoolClassStep >= 5 && schoolClassStep < 7 ? allTimes[0] : allTimes[1]
                        }
                    }
                    
                    if schoolClass.contains(" ") {
                        let schoolClassStepString = (schoolClass as NSString).substring(to: schoolClass.indexOf(" "))
                        if let schoolClassStep = Int(schoolClassStepString) {
                            times = schoolClassStep >= 5 && schoolClassStep < 7 ? allTimes[0] : allTimes[1]
                        }
                    }
                }
                
                if times == nil {
                    times = allTimes[1]
                }
            } else {
                times = settings.schoolClassStep < 7 ? allTimes[0] : allTimes[1]
            }
            
            if let times = times {
                let hourIndex: Int
                if let timetable = timetable {
                    hourIndex = TimetableData.getHourForIndex(timetable[week][day], subjectIndex: (indexPath as NSIndexPath).section) - 1
                } else {
                    if let hour = subject.hour {
                        hourIndex = hour - 1
                    } else {
                        hourIndex = -1
                    }
                }
                
                if hourIndex >= 0 && hourIndex < times.count {
                    let subjectTimes: [String] = times[hourIndex]
                    cell.startTimeLabel.text = subjectTimes[0]
                    cell.endTimeLabel.text = subjectTimes[1]
                } else {
                    cell.startTimeLabel.text = ""
                    cell.endTimeLabel.text = ""
                }
            }
            
            cell.hourLabel.text = "\(subject.hour!)."
            cell.roomLabel.text = subject.room!
            cell.teacherOrSchoolClassLabel.text = subject.teacherOrSchoolClass!
            
            if let subject = subject.subject , !subject.isEmpty {
                cell.subjectLabel.text = subject
            } else {
                cell.subjectLabel.text = "[ Freistunde ]"
            }
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 8
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionHeader = UIView()
        sectionHeader.backgroundColor = UIColor.clear
        return sectionHeader
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // update data
            timetable![week][day].remove(at: (indexPath as NSIndexPath).section)
            TimetableData.correctHours(timetable![week][day])
            
            // update table
            let indexSet = IndexSet(integer: (indexPath as NSIndexPath).section)
            tableView.deleteSections(indexSet, with: .fade)
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(250 * Double(NSEC_PER_MSEC))) / Double(NSEC_PER_SEC)) {
                
                var indexPaths = [IndexPath]()
                
                for index in (indexPath as NSIndexPath).section..<tableView.numberOfSections {
                    let indexPath = IndexPath(row: 0, section: index)
                    indexPaths.append(indexPath)
                }
                
                tableView.reloadRows(at: indexPaths, with: .fade)
            }
        }
        
        timetableManager.setTimetable(timetable!)
        if (timetable == nil || timetable!.isEmpty || timetable![week][day].isEmpty) {
            tableView.setEditing(false, animated: false)
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EditSubject" {
            let subjectDetailViewController = segue.destination as! TimetableSubjectDetailViewController
            
            subjectDetailViewController.day = getNameForDay(day)
            subjectDetailViewController.navigationItem.title = subjectDetailViewController.day
            
            // get the cell that generated the segue
            if let selectedSubjectCell = sender as? UITableViewCell {
                let indexPath = tableView.indexPath(for: selectedSubjectCell)!
                let selectedSubject = timetable![week][day][(indexPath as NSIndexPath).section]
                subjectDetailViewController.subject = selectedSubject
                subjectDetailViewController.hour = TimetableData.getHourForIndex(timetable![week][day], subjectIndex: (indexPath as NSIndexPath).section)
            }
        } else if segue.identifier == "AddSubject" {
            print("Adding new subject.", terminator: "")
            
            let subjectDetailViewController = (segue.destination as! UINavigationController).viewControllers[0] as! TimetableSubjectDetailViewController
            
            subjectDetailViewController.day = getNameForDay(day)
            subjectDetailViewController.navigationItem.title = subjectDetailViewController.day
            
            subjectDetailViewController.hour = TimetableData.getHourForIndex(timetable![week][day], subjectIndex: timetable![week][day].count)
            tableView.setEditing(false, animated: true)
        }
        
    }
    
    func getNameForDay(_ dayIndex: Int) -> String {
        let dayName: String!
        
        switch(day) {
        case 0:
            dayName = "Montag"
        case 1:
            dayName = "Dienstag"
        case 2:
            dayName = "Mittwoch"
        case 3:
            dayName = "Donnerstag"
        case 4:
            dayName = "Freitag"
        default:
            dayName = "Tag \(day + 1)"
        }
        
        return dayName
    }
    
    // MARK: Actions
    
    @IBAction func weekSegmentSelected(_ sender: UISegmentedControl) {
        print("selected week \(sender.selectedSegmentIndex)", terminator: "")
        
        week = sender.selectedSegmentIndex
        
        tableView.reloadData()
    }
    
    @IBAction func daySegmentSelected(_ sender: UISegmentedControl) {
        print("selected day \(sender.selectedSegmentIndex)", terminator: "")
        
        day = sender.selectedSegmentIndex
        
        tableView.reloadData()
    }
    
    @IBAction func unwingToTimetable(_ sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? TimetableSubjectDetailViewController, let subject = sourceViewController.subject {
            let section = TimetableData.getIndexFourHour(timetable![week][day], hour: subject.hour!)
            if section < tableView.numberOfSections {
                // updating an existing subject
                timetable![week][day][section] = subject
                TimetableData.correctHours(timetable![week][day])
                
                var indexPaths = [IndexPath]()
                
                for index in section..<tableView.numberOfSections {
                    let indexPath = IndexPath(row: 0, section: index)
                    indexPaths.append(indexPath)
                }
                
                tableView.reloadRows(at: indexPaths, with: .fade)
            } else {
                // add a new subject
                let newIndexSet = IndexSet(integer: section)
                timetable![week][day].append(subject)
                tableView.insertSections(newIndexSet, with: .bottom)
            }
        }
        
        timetableManager.setTimetable(timetable!)
    }
    
    @IBAction func showTimesItemPressed(_ sender: UIBarButtonItem) {
        showTimes = !showTimes
        tableView.reloadData()
    }
    
    @IBAction func copieWeekItemPressed(_ sender: UIBarButtonItem) {
        let selectedWeekName = week == 0 ? "A" : "B"
        let notSelectedWeekName = week == 0 ? "B" : "A"
        let alertController = UIAlertController(title: "Woche kopieren", message: "Der Inhalt von Woche \(selectedWeekName) wird in Woche \(notSelectedWeekName) kopiert. Dabei werden alle Fächer in Woche \(notSelectedWeekName) überschrieben. Fortfahren?", preferredStyle: .alert)
        alertController.view.tintColor = UIColor.franziskaneum
        alertController.addAction(UIAlertAction(title: "Ja", style: .default, handler: { (action: UIAlertAction) in
            if let timetable = self.timetable , timetable.count > self.week {
                let timetableWeek = timetable[self.week]
                let destinationWeek = self.week == 0 ? 1 : 0
                
                for dayIndex in 0..<5 {
                    if (timetableWeek.count > dayIndex && self.timetable![destinationWeek].count > dayIndex) {
                        let timetableDay = timetableWeek[dayIndex]
                        
                        self.timetable![destinationWeek][dayIndex].removeAll()
                        self.timetable![destinationWeek][dayIndex] += timetableDay
                    }
                }
            }
        }))
        alertController.addAction(UIAlertAction(title: "Abbrechen", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func deleteItemPressed(_ sender: UIBarButtonItem) {
        if (tableView.isEditing) {
            tableView.setEditing(false, animated: true)
        } else {
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            actionSheet.view.tintColor = UIColor.franziskaneum
            actionSheet.addAction(UIAlertAction(title: "Fach löschen", style: .default, handler: { (action: UIAlertAction) in
                self.tableView.setEditing(true, animated: true)
            }))
            actionSheet.addAction(UIAlertAction(title: "Woche löschen", style: .default, handler: { (action: UIAlertAction) in
                let alertController = UIAlertController(title: "Woche löschen", message: "Bist du sicher, dass du die aktuelle Woche löschen möchtest?", preferredStyle: .alert)
                alertController.view.tintColor = UIColor.franziskaneum
                alertController.addAction(UIAlertAction(title: "Ja", style: .default, handler: { (action: UIAlertAction) in
                    if (self.timetable != nil && self.timetable?.count > self.week) {
                        if let timetableWeek = self.timetable?[self.week] {
                            for dayIndex in 0..<timetableWeek.count {
                                self.timetable![self.week][dayIndex].removeAll()
                            }
                            self.tableView.reloadData()
                            self.timetableManager.setTimetable(self.timetable!)
                        }
                    }
                }))
                alertController.addAction(UIAlertAction(title: "Abbrechen", style: .cancel, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            }))
            actionSheet.addAction(UIAlertAction(title: "Alles löschen", style: .default, handler: { (action: UIAlertAction) in
                let alertController = UIAlertController(title: "Alles löschen", message: "Bist du sicher, dass du deinen kompletten Stundenplan löschen möchtest?", preferredStyle: .alert)
                alertController.view.tintColor = UIColor.franziskaneum
                alertController.addAction(UIAlertAction(title: "Ja", style: .default, handler: { (action: UIAlertAction) in
                    if (self.timetable != nil) {
                        for weekIndex in 0..<self.timetable!.count {
                            for dayIndex in 0..<self.timetable![weekIndex].count {
                                self.timetable![weekIndex][dayIndex].removeAll()
                            }
                        }
                        self.tableView.reloadData()
                        self.timetableManager.setTimetable(self.timetable!)
                    }
                }))
                alertController.addAction(UIAlertAction(title: "Abbrechen", style: .cancel, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            }))
            actionSheet.addAction(UIAlertAction(title: "Abbrechen", style: .cancel, handler: nil))
            actionSheet.popoverPresentationController?.barButtonItem = sender
            present(actionSheet, animated: true, completion: nil)
        }
    }
    
}
