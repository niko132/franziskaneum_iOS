//
//  TeacherTableViewCell.swift
//  Franziskaneum
//
//  Created by Niko Kirste on 19.01.16.
//  Copyright © 2016 Franziskaneum. All rights reserved.
//

import UIKit

class TeacherTableViewCell: UITableViewCell {

    // MARK: Properties
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var subjectsLabel: UILabel!
    @IBOutlet weak var shortcutLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        makeCircleAroundLabel()
    }
    
    func makeCircleAroundLabel() {
        // modify layer to reach a circle around the label
        shortcutLabel.layoutIfNeeded()
        shortcutLabel.layer.cornerRadius = shortcutLabel.bounds.width / 2.0
    }
    
    func setCircleBackgroundColor(_ color: UIColor) {
        shortcutLabel.backgroundColor = UIColor.clear
        shortcutLabel.layer.backgroundColor = color.cgColor
    }

}
