//
//  NewsArticlePhoto.swift
//  Franziskaneum
//
//  Created by Niko Kirste on 30.01.16.
//  Copyright © 2016 Franziskaneum. All rights reserved.
//

import UIKit
import NYTPhotoViewer

class NewsArticlePhoto: NSObject, NYTPhoto {
    
    var image: UIImage?
    var smallImage: UIImage?
    var smallImageUrl: String?
    var largeImageUrl: String? {
        get {
            return smallImageUrl?.replacingOccurrences(of: "-150x150", with: "")
        }
    }
    var isLargeImageLoaded = false
    
    var imageData: Data?
    var placeholderImage: UIImage?
    let attributedCaptionTitle: NSAttributedString?
    let attributedCaptionSummary: NSAttributedString? = nil
    let attributedCaptionCredit: NSAttributedString? = nil
    
    init(image: UIImage? = nil, smallImageUrl: String?, isSmallImage: Bool = true, description: String? = "") {
        self.image = image
        self.smallImageUrl = smallImageUrl
        if let description = description {
            let font = UIFont.systemFont(ofSize: 16.0)
            self.attributedCaptionTitle = NSAttributedString(string: description, attributes: [NSForegroundColorAttributeName: UIColor.white, NSFontAttributeName: font])
        } else {
            self.attributedCaptionTitle = nil
        }
        super.init()
    }
    
}
