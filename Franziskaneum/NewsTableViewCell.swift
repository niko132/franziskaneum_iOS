//
//  NewsTableViewCell.swift
//  Franziskaneum
//
//  Created by Niko Kirste on 22.01.16.
//  Copyright © 2016 Franziskaneum. All rights reserved.
//

import UIKit

class NewsTableViewCell: UITableViewCell {
    
    // MARK: Properties
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
