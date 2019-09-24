//
//  NewsOlderPostsTableViewCell.swift
//  Franziskaneum
//
//  Created by Niko Kirste on 24.01.16.
//  Copyright © 2016 Franziskaneum. All rights reserved.
//

import UIKit

class NewsOlderPostsTableViewCell: UITableViewCell {
    
    // MARK: Properties
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
