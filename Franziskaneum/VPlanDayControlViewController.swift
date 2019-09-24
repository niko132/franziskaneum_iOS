//
//  VPlanDayControlViewController.swift
//  Franziskaneum
//
//  Created by Niko Kirste on 27.03.16.
//  Copyright © 2016 Franziskaneum. All rights reserved.
//

import UIKit

class VPlanDayControlViewController: UIViewController {
    
    @IBOutlet weak var generalMyChangesSegementedControl: UISegmentedControl!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var loadingContainer: UIView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var navHairlineConstraint: NSLayoutConstraint!
    
    var navHairlineImageView: UIImageView?
    
    var generalVPlanDayViewController: VPlanDayTableViewController?
    var myChangesDayViewController: VPlanDayTableViewController?
    var noChangesViewController: UIViewController?
    var activeViewController: UIViewController?
    
    var vplanTitle: String?
    var generalVPlanDay: VPlanDayData?
    var myChangesVPlanDay: VPlanDayData?
    var showMyChangesSegment: Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadingIndicator.startAnimating()
        
        DispatchQueue.main.async {
            self.segmentSelected(self.generalMyChangesSegementedControl)
        }
        
        if let vplanDay = generalVPlanDay {
            DispatchQueue.global(qos: .default).async {
                var tmpVPlan: [VPlanDayData] = [vplanDay.copy() as! VPlanDayData]
                VPlanNotificationManager.instance.filterNotificationVPlan(&tmpVPlan)
                if tmpVPlan.count > 0 {
                    self.myChangesVPlanDay = tmpVPlan[0]
                    if let dayViewController = self.myChangesDayViewController {
                        dayViewController.vplanDay = tmpVPlan[0]
                        
                        DispatchQueue.main.async {
                            dayViewController.tableView.reloadData()
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.segmentSelected(self.generalMyChangesSegementedControl)
                        }
                    }
                }
            }
        } else if let title = vplanTitle {
            VPlanManager.instance.getVPlan(.cache, completionHandler: { (vplan: [VPlanDayData]?, mode: VPlanLoadingMode, error: FranziskaneumError?) in
                if let vplan = vplan {
                    for day in vplan {
                        if day.title == title {
                            self.generalVPlanDay = day
                            if let dayViewController = self.generalVPlanDayViewController {
                                dayViewController.vplanDay = day
                                
                                DispatchQueue.main.async {
                                    dayViewController.tableView.reloadData()
                                }
                            } else {
                                DispatchQueue.main.async {
                                    self.segmentSelected(self.generalMyChangesSegementedControl)
                                }
                            }
                            self.navigationItem.title = day.getNameOfDay()
                            
                            var tmpVPlan: [VPlanDayData] = [day.copy() as! VPlanDayData]
                            VPlanNotificationManager.instance.filterNotificationVPlan(&tmpVPlan)
                            if tmpVPlan.count > 0 {
                                self.myChangesVPlanDay = tmpVPlan[0]
                                if let dayViewController = self.myChangesDayViewController {
                                    dayViewController.vplanDay = tmpVPlan[0]
                                    
                                    DispatchQueue.main.async {
                                        dayViewController.tableView.reloadData()
                                    }
                                } else {
                                    DispatchQueue.main.async {
                                        self.segmentSelected(self.generalMyChangesSegementedControl)
                                    }
                                }
                            }
                            
                            break
                        }
                    }
                }
                
                if let navigationController = self.navigationController, self.generalVPlanDay == nil {
                    navigationController.popViewController(animated: true)
                }
            })
        } else if let navigationController = self.navigationController {
                navigationController.popViewController(animated: true)
        }
        
        // modify the hairline image ;)
        navHairlineImageView = findHairlineImageViewUnder((navigationController?.navigationBar)!)
        navHairlineConstraint.constant = 0.5
        
        DispatchQueue.main.async {
            if let showMyChangesSegment = self.showMyChangesSegment, showMyChangesSegment {
                self.generalMyChangesSegementedControl.selectedSegmentIndex = 1
                self.segmentSelected(self.generalMyChangesSegementedControl)
                
                DispatchQueue.main.async {
                    if let vplanTableViewController = self.activeViewController as? VPlanDayTableViewController {
                        let indexPath = IndexPath(row: vplanTableViewController.firstTableRow() ?? 0, section: 0)
                        vplanTableViewController.tableView.scrollToRow(at: indexPath, at: UITableViewScrollPosition.top, animated: true)
                    }
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navHairlineImageView?.isHidden = true
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(1 * Double(NSEC_PER_MSEC))) / Double(NSEC_PER_SEC)) {
            self.navHairlineImageView?.isHidden = false
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Action
    
    @IBAction func segmentSelected(_ sender: UISegmentedControl) {
        print("selected segment \(sender.selectedSegmentIndex)")
        
        if let _ = generalVPlanDay, sender.selectedSegmentIndex == 0 {
            if generalVPlanDayViewController == nil {
                generalVPlanDayViewController = self.storyboard?.instantiateViewController(withIdentifier: "VPlanDayTableViewController") as? VPlanDayTableViewController
            }
            
            if let oldViewController = activeViewController {
                oldViewController.willMove(toParentViewController: nil)
                oldViewController.view.removeFromSuperview()
                oldViewController.removeFromParentViewController()
            }
            
            if let newViewController = generalVPlanDayViewController {
                newViewController.vplanDay = generalVPlanDay
                addChildViewController(newViewController)
                newViewController.view.frame = contentView.bounds
                contentView.addSubview(newViewController.view)
                newViewController.didMove(toParentViewController: self)
            }
            
            activeViewController = generalVPlanDayViewController
        } else if let _ = myChangesVPlanDay, sender.selectedSegmentIndex == 1 {
            if myChangesDayViewController == nil {
                myChangesDayViewController = self.storyboard?.instantiateViewController(withIdentifier: "VPlanDayTableViewController") as? VPlanDayTableViewController
            }
            
            if let oldViewController = activeViewController {
                
                oldViewController.willMove(toParentViewController: nil)
                oldViewController.view.removeFromSuperview()
                oldViewController.removeFromParentViewController()
            }
            
            if let newViewController = myChangesDayViewController {
                newViewController.vplanDay = myChangesVPlanDay
                
                addChildViewController(newViewController)
                
                newViewController.view.frame = contentView.bounds
                contentView.addSubview(newViewController.view)
                newViewController.didMove(toParentViewController: self)
            }
            
            activeViewController = myChangesDayViewController
        } else {
            if noChangesViewController == nil {
                noChangesViewController = self.storyboard?.instantiateViewController(withIdentifier: "VPlanDayNoChangesViewController")
            }
            
            if let oldViewController = activeViewController {
                oldViewController.willMove(toParentViewController: nil)
                oldViewController.view.removeFromSuperview()
                oldViewController.removeFromParentViewController()
            }
            
            if let newViewController = noChangesViewController {
                addChildViewController(newViewController)
                newViewController.view.frame = contentView.bounds
                contentView.addSubview(newViewController.view)
                newViewController.didMove(toParentViewController: self)
            }
            
            activeViewController = noChangesViewController
        }
        
        DispatchQueue.main.async {
            self.loadingContainer.isHidden = true
        }
    }
    
}
