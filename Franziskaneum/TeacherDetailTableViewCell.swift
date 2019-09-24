//
//  TeacherDetailTableViewCell.swift
//  Franziskaneum
//
//  Created by Niko Kirste on 05.06.16.
//  Copyright © 2016 Franziskaneum. All rights reserved.
//

import UIKit
import TTTAttributedLabel

class TeacherDetailTableViewCell: UITableViewCell {
    
    // MARK: Properties
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var valueLabel: TTTAttributedLabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let linkColor = UIColor(red: 162.0/255.0, green: 14.0/255.0, blue: 12.0/255.0, alpha: 1.0)
        let activeLinkColor = linkColor.withAlphaComponent(0.5)
        
        let linkAttributes = [NSForegroundColorAttributeName: linkColor, NSUnderlineStyleAttributeName: NSNumber(value: NSUnderlineStyle.styleSingle.rawValue)]
        let activeLinkAttributes = [NSForegroundColorAttributeName: activeLinkColor, NSUnderlineStyleAttributeName: NSNumber(value: NSUnderlineStyle.styleSingle.rawValue)]
        
        valueLabel.linkAttributes = linkAttributes
        valueLabel.activeLinkAttributes = activeLinkAttributes
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
