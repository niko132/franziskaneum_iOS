//
//  NewsData.swift
//  Franziskaneum
//
//  Created by Niko Kirste on 22.01.16.
//  Copyright © 2016 Franziskaneum. All rights reserved.
//

import UIKit

class NewsData {
    
    // MARK: Properties
    
    var title: String?
    var previewContent: NSAttributedString?
    var articleUrl: String?
    var imageUrl: String?
    var baseImage: UIImage?
    var fullContent: NSAttributedString?
    var images: [ArticleImageData]?
    var isFullContent = false
    
    init() {
        
    }
    
    class ArticleImageData {
        
        // MARK: Properties
        
        var url: String?
        var description: String?
        var image: UIImage?
        
    }
    
}