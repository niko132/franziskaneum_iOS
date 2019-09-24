//
//  VPlanDayTableViewCell.swift
//  Franziskaneum
//
//  Created by Niko Kirste on 08.02.16.
//  Copyright © 2016 Franziskaneum. All rights reserved.
//

import UIKit
import TTTAttributedLabel

class VPlanDayTableViewCell: UITableViewCell {
    
    // MARK: Properties
    
    @IBOutlet weak var schoolClassLabel: UILabel!
    @IBOutlet weak var hourLabel: UILabel!
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var teacherLabel: TTTAttributedLabel!
    @IBOutlet weak var roomLabel: UILabel!
    @IBOutlet weak var infoLabel: TTTAttributedLabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
