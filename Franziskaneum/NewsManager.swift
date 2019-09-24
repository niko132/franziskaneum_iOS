//
//  NewsManager.swift
//  Franziskaneum
//
//  Created by Niko Kirste on 22.01.16.
//  Copyright © 2016 Franziskaneum. All rights reserved.
//

import Foundation
import UIKit

class NewsManager {
    
    // MARK: Properties
    
    static let baseUrl = "http://www.franziskaneum.de/wordpress/category/aktuelles/"
    fileprivate static var nextUrl: String? = baseUrl
    
    static let instance = NewsManager()
    
    fileprivate var news: [NewsData]?
    
    fileprivate init() {
    }
    
    func getNews(_ refresh: Bool, completionHandler: @escaping (_ news: [NewsData]?, _ error: FranziskaneumError?) -> Void) {
        if let news = news , !refresh {
            completionHandler(news, nil)
        } else {
            DispatchQueue.global(qos: .default).async {
                self.downloadNewsData(NewsManager.baseUrl) { (data: Data?, error: FranziskaneumError?) in
                    if let data = data {
                        let returnValue = self.parseNewsWithData(data)
                        
                        if let news = returnValue.news {
                            if let _ = self.news , !refresh {
                                self.news! += news
                            } else {
                                self.news = news
                            }
                            
                            completionHandler(news, nil)
                        } else if let error = returnValue.error {
                            completionHandler(nil, error)
                        } else {
                            completionHandler(nil, .unknownError)
                        }
                    } else if let error = error {
                        completionHandler(nil, error)
                    } else {
                        completionHandler(nil, .unknownError)
                    }
                }
            }
        }
    }
    
    func olderPostsAvailabe() -> Bool {
        return NewsManager.nextUrl != nil && !NewsManager.nextUrl!.isEmpty
    }
    
    func loadOlderPosts(_ completionHandler: @escaping (_ news: [NewsData]?, _ error: FranziskaneumError?) -> Void) {
        if let nextUrl = NewsManager.nextUrl {
            DispatchQueue.global(qos: .default).async {
                self.downloadNewsData(nextUrl) { (data: Data?, error: FranziskaneumError?) in
                    if let data = data {
                        let returnValue = self.parseNewsWithData(data)
                        
                        if let news = returnValue.news {
                            if let _ = self.news {
                                self.news! += news
                            } else {
                                self.news = news
                            }
                            
                            completionHandler(self.news, nil)
                        } else if let error = returnValue.error {
                            completionHandler(nil, error)
                        } else {
                            completionHandler(nil, .unknownError)
                        }
                    } else if let error = error {
                        completionHandler(nil, error)
                    } else {
                        completionHandler(nil, .unknownError)
                    }
                }
            }
        } else {
            completionHandler(nil, .noMoreContentAvailable)
        }
    }
    
    func getArticle(_ articleUrl: String, completionHandler: @escaping (_ articleContent: NSAttributedString?, _ images: [NewsData.ArticleImageData]?, _ error: FranziskaneumError?) -> Void) {
        DispatchQueue.global(qos: .default).async {
            self.downloadArticleData(articleUrl) { (data: Data?, error: FranziskaneumError?) in
                if let data = data {
                    let returnValue = self.parseArticleWithData(data)
                    
                    if let articleContent = returnValue.articleContent {
                        completionHandler(articleContent, returnValue.images, nil)
                    } else if let error = returnValue.error {
                        completionHandler(nil, nil, error)
                    } else {
                        completionHandler(nil, nil, .unknownError)
                    }
                } else if let error = error {
                    completionHandler(nil, nil, error)
                } else {
                    completionHandler(nil, nil, .unknownError)
                }
            }
        }
    }
    
    fileprivate func downloadArticleData(_ articleUrl: String, completionHandler: @escaping (_ data: Data?, _ error: FranziskaneumError?) -> Void) {
        let articleSession = URLSession(configuration: URLSessionConfiguration.default)
        let articleRequest = URLRequest(url: URL(string: articleUrl)!)
        let articleTask = articleSession.dataTask(with: articleRequest, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if let data = data {
                completionHandler(data, nil)
            } else {
                completionHandler(nil, .networkError)
            }
        })
        articleTask.resume()
    }
    
    fileprivate func parseArticleWithData(_ data: Data) -> (articleContent: NSAttributedString?, images: [NewsData.ArticleImageData]?, error: FranziskaneumError?) {
        let parser = TFHpple(data: data, encoding: "UTF-8", isXML: false)
        
        var attributedArticleContent: NSAttributedString?
        var images: [NewsData.ArticleImageData]?
        
        if let sectionElement = (parser?.search(withXPathQuery: "//section") as! [TFHppleElement]).first {
            /**
             var articleContent: String?
             
             for p in section.searchWithXPathQuery("//p") as! [TFHppleElement] {
             if let content = p.content.trim().nilIfEmpty() {
             if articleContent == nil {
             articleContent = content
             } else {
             articleContent! += "\n\n\(content)"
             }
             }
             }
             **/
            
            var contentHtml = sectionElement.raw

            
            for galleryElement in sectionElement.search(withXPathQuery: "//*[@class='gallery']") as! [TFHppleElement] {
                for galleryItem in galleryElement.search(withXPathQuery: "//*[@class='gallery-item']") as! [TFHppleElement] {
                    let articleImage = NewsData.ArticleImageData()
                    if images == nil {
                        images = []
                    }
                    images?.append(articleImage)
                    
                    let image = (galleryItem.search(withXPathQuery: "//img") as! [TFHppleElement]).first!
                    if let imageUrl = image.attributes["src"] as? String {
                        articleImage.url = imageUrl.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
                    }
                    
                    if let description = (galleryItem.search(withXPathQuery: "//*[@class='wp-caption-text gallery-caption']") as! [TFHppleElement]).first {
                        articleImage.description = description.content.trim().nilIfEmpty()
                    }
                }
                
                // remove the gallery (-caption) from the content
                let galleryHtml = galleryElement.raw
                contentHtml = contentHtml?.replacingOccurrences(of: galleryHtml!, with: "")
            }
            
            //remove all images from the content
            for imageElement in sectionElement.search(withXPathQuery: "//img") as! [TFHppleElement] {
                let imageHtml = imageElement.raw
                contentHtml = contentHtml?.replacingOccurrences(of: imageHtml!, with: "");
            }
            
            do {
                attributedArticleContent = try NSAttributedString(data: (contentHtml?.data(using: String.Encoding.utf16)!)!, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil).trim()
            } catch {
                print(error)
            }
        }
        
        return (attributedArticleContent, images, nil)
        // return (articleContent, images, nil)
    }
    
    fileprivate func downloadNewsData(_ url: String, completionHandler: @escaping (_ data: Data?, _ error: FranziskaneumError?) -> Void) {
        let newsSession = URLSession(configuration: URLSessionConfiguration.default)
        let newsRequest = URLRequest(url: URL(string: url)!)
        let newsTask = newsSession.dataTask(with: newsRequest, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if let data = data {
                completionHandler(data, nil)
            } else {
                completionHandler(nil, .networkError)
            }
        })
        newsTask.resume()
    }
    
    fileprivate func parseNewsWithData(_ data: Data) -> (news: [NewsData]?, error: FranziskaneumError?) {
        let parser = TFHpple(data: data, isXML: false)
        
        NewsManager.nextUrl = ((parser?.search(withXPathQuery: "//*[contains(@class, 'nav-previous')]") as! [TFHppleElement]).first?.search(withXPathQuery: "//a") as! [TFHppleElement]).first?.attributes["href"] as? String
        
        var news: [NewsData]?
        
        for articleElement in parser?.search(withXPathQuery: "//article") as! [TFHppleElement] {
            if news == nil {
                news = [NewsData]()
            }
            let newsArticle = NewsData()
            news?.append(newsArticle)
            
            if let headerElement = (articleElement.search(withXPathQuery: "//header") as! [TFHppleElement]).first {
                newsArticle.title = (headerElement.search(withXPathQuery: "//*[contains(@class, 'entry-title')]") as! [TFHppleElement]).first?.content.trim()
            }
            
            if let sectionElement = (articleElement.search(withXPathQuery: "//section") as! [TFHppleElement]).first {
                var contentHtml = sectionElement.raw
                
                // remove the "read more" link (-text)
                if let moreLinkElement = (sectionElement.search(withXPathQuery: "//*[contains(@class, 'more-link')]") as! [TFHppleElement]).first {
                    newsArticle.articleUrl = moreLinkElement.attributes["href"] as? String
                    
                    let moreLinkHtml = moreLinkElement.raw
                    contentHtml = contentHtml?.replacingOccurrences(of: moreLinkHtml!, with: "")
                }
                
                //remove all images from the content
                for imageElement in sectionElement.search(withXPathQuery: "//img") as! [TFHppleElement] {
                    let imageHtml = imageElement.raw
                    contentHtml = contentHtml?.replacingOccurrences(of: imageHtml!, with: "");
                }
                
                var attributedPreviewContent: NSMutableAttributedString?
                do {
                    attributedPreviewContent = try NSMutableAttributedString(data: (contentHtml?.data(using: String.Encoding.utf16)!)!, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil)
                } catch {
                    print(error)
                }
                
                newsArticle.previewContent = attributedPreviewContent?.trim()
                
                if let imageTag = (sectionElement.search(withXPathQuery: "//img") as! [TFHppleElement]).first {
                    if let imageUrl = imageTag.attributes["src"] as? String {
                        newsArticle.imageUrl = imageUrl.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
                    }
                }
            }
            
            /**
            var contentText = (content.searchWithXPathQuery("//*[contains(@class, 'entry-content')]") as! [TFHppleElement]).first!.content.stringByReplacingOccurrencesOfString("\n", withString: "\n\n").trim()
            
            if contentText.lowercaseString.hasSuffix("weiterlesen") {
                let suffixRange = contentText.endIndex.advancedBy(-11)..<contentText.endIndex
                contentText.removeRange(suffixRange)
                contentText = contentText.trim()
            }
            
            newsArticle.previewContent = contentText.nilIfEmpty()
 **/
 **/
        }
        
        return (news, nil)
    }
    
}
