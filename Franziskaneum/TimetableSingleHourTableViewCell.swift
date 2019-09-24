//
//  TimetableSingleHourTableViewCell.swift
//  Franziskaneum
//
//  Created by Niko Kirste on 15.01.16.
//  Copyright © 2016 Franziskaneum. All rights reserved.
//

import UIKit

class TimetableSingleHourTableViewCell: UITableViewCell {
    
    // MARK: Properties

    @IBOutlet weak var hourLabel: UILabel!
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var roomLabel: UILabel!
    @IBOutlet weak var teacherOrSchoolClassLabel: UILabel!
    @IBOutlet weak var timesView: UIView!
    @IBOutlet weak var dividerWithConstraint: NSLayoutConstraint!
    @IBOutlet weak var timesViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var startTimeLabel: UILabel!
    @IBOutlet weak var endTimeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
