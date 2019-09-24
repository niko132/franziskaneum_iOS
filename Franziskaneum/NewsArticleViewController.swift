//
//  NewsArticleViewController.swift
//  Franziskaneum
//
//  Created by Niko Kirste on 30.05.16.
//  Copyright © 2016 Franziskaneum. All rights reserved.
//

import UIKit
import NYTPhotoViewer
import TTTAttributedLabel
import SDWebImage

class NewsArticleViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, NYTPhotosViewControllerDelegate, TTTAttributedLabelDelegate {
    
    // MARK: Properties
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentLabel: TTTAttributedLabel!
    @IBOutlet weak var imagesCollectionView: UICollectionView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var backgroundView: UIView!
    
    @IBOutlet weak var imagesCollectionViewHeight: NSLayoutConstraint!
    
    var article: NewsData?
    var photos: [NewsArticlePhoto] = []
    
    var photosViewController: NYTPhotosViewController?
    
    var originalImageViewHeight: CGFloat = 0.0
    var currentImageViewHeight: CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let linkColor = UIColor(red: 162.0/255.0, green: 14.0/255.0, blue: 12.0/255.0, alpha: 1.0)
        let activeLinkColor = linkColor.withAlphaComponent(0.5)
        
        let linkAttributes = [NSForegroundColorAttributeName: linkColor, NSUnderlineStyleAttributeName: NSNumber(value: NSUnderlineStyle.styleSingle.rawValue)]
        let activeLinkAttributes = [NSForegroundColorAttributeName: activeLinkColor, NSUnderlineStyleAttributeName: NSNumber(value: NSUnderlineStyle.styleSingle.rawValue)]
        
        contentLabel.linkAttributes = linkAttributes
        contentLabel.activeLinkAttributes = activeLinkAttributes
        
        if let article = article {
            titleLabel.text = article.title
            imageView.clipsToBounds = true
            imageView.contentMode = UIViewContentMode.scaleAspectFill
            if let imageUrl = article.imageUrl , !imageUrl.isEmpty {
                imageView.sd_setImage(with: URL(string: imageUrl.replacingOccurrences(of: "-150x150", with: "")))
            } else {
                imageView.image = UIImage(named: "FranziskaneumBanner")
            }
            
            if let articleUrl = article.articleUrl , !articleUrl.isEmpty {
                NewsManager.instance.getArticle(articleUrl, completionHandler: { (articleContent: NSAttributedString?, images: [NewsData.ArticleImageData]?, error: FranziskaneumError?) -> Void in
                    article.fullContent = articleContent
                    article.isFullContent = true
                    article.images = images
                    
                    if let images = images {
                        for image in images {
                            self.photos.append(NewsArticlePhoto(image: image.image, smallImageUrl: image.url, description: image.description))
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.contentLabel.attributedTextLabelFont = articleContent
                        self.contentLabel.addLinksFromAttributedText()
                        self.imagesCollectionView.reloadData()
                        
                        self.updateImagesCollectionViewHeight()
                    }
                })
            } else {
                contentLabel.attributedTextLabelFont = article.previewContent
                contentLabel.addLinksFromAttributedText()
                DispatchQueue.main.async {
                    self.updateImagesCollectionViewHeight()
                }
            }
        }
        
        DispatchQueue.main.async {
            self.originalImageViewHeight = self.view.frame.height / 3.0
            self.scrollViewDidScroll(self.scrollView)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        DispatchQueue.main.async {
            self.originalImageViewHeight = self.view.frame.height / 3.0
            self.scrollViewDidScroll(self.scrollView)
            
            self.updateImagesCollectionViewHeight()
        }
    }
    
    fileprivate func updateImagesCollectionViewHeight() -> Void {
        if article?.articleUrl == nil || (article?.fullContent != nil && article?.images == nil) {
            self.imagesCollectionViewHeight.constant = 0.0
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let restorationIdentifier = scrollView.restorationIdentifier , restorationIdentifier == "NewsArticleViewControllerContentScrollView" {
            let newSize = max(self.originalImageViewHeight * ((self.imageView.frameBottom - scrollView.contentOffset.y ) / self.imageView.frameBottom), 0.0)
            
            self.imageView.frame.origin.y = self.imageView.frameBottom - newSize
            self.imageView.frame.origin.x = self.imageView.frame.origin.x + (self.imageView.frame.width - newSize) / 2.0
            
            self.backgroundView.frame.size.height = self.backgroundView.frame.height - (self.imageView.frame.height - newSize) / 2.0
            
            self.imageView.frame.size.width = newSize
            self.imageView.frame.size.height = newSize
            self.imageView.maskCircle()
            
            self.backgroundView.frame.origin.y = self.imageView.frameHalfHeight
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if self.view.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClass.regular && self.view.traitCollection.verticalSizeClass == UIUserInterfaceSizeClass.regular {
            return CGSize(width: 141.0, height: 141.0)
        }
        
        return CGSize(width: 91.0, height: 91.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewsArticleImagesCollectionViewCell", for: indexPath) as! NewsArticleCollectionViewCell
        
        let photo = photos[(indexPath as NSIndexPath).item]
        
        if let smallImage = photo.smallImage {
            cell.imageView.image = smallImage
        } else if let image = photo.image {
            cell.imageView.image = image
        } else {
            cell.imageView.sd_setImage(with: URL(string: photo.smallImageUrl!), completed: { (image: UIImage?, error: Error?, cacheType: SDImageCacheType, imageURL: URL?) -> Void in
                self.photos[(indexPath as NSIndexPath).item].smallImage = image
                if self.photos[(indexPath as NSIndexPath).item].image == nil {
                    self.photos[(indexPath as NSIndexPath).item].image = image
                    if let photosViewController = self.photosViewController {
                        photosViewController.updateImage(for: self.photos[(indexPath as NSIndexPath).item])
                    }
                }
            })
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).item < photos.count {
            photosViewController = NYTPhotosViewController(photos: photos, initialPhoto: photos[(indexPath as NSIndexPath).item])
            photosViewController?.delegate = self
            
            loadLargeImagesAtIndex((indexPath as NSIndexPath).item)
            
            present(photosViewController!, animated: true, completion: nil)
        }
        
        collectionView.deselectItem(at: indexPath, animated: false)
    }
    
    func photosViewController(_ photosViewController: NYTPhotosViewController, referenceViewFor photo: NYTPhoto) -> UIView? {
        if let index = photos.index(of: photo as! NewsArticlePhoto) , index >= 0 {
            return (imagesCollectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? NewsArticleCollectionViewCell)?.imageView
        } else {
            return imageView
        }
    }
    
    func photosViewControllerWillDismiss(_ photosViewController: NYTPhotosViewController) {
        self.photosViewController = nil
        
        DispatchQueue.main.async {
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
            self.scrollViewDidScroll(self.scrollView)
        }
    }
    
    /**
     func photosViewControllerDidDismiss(photosViewController: NYTPhotosViewController) {
     self.photosViewController = nil
     
     self.view.setNeedsLayout()
     self.view.layoutIfNeeded()
     }
     **/
    
    func photosViewController(_ photosViewController: NYTPhotosViewController, didNavigateTo photo: NYTPhoto, at photoIndex: UInt) {
        loadLargeImagesAtIndex(Int(photoIndex))
    }
    
    func loadLargeImagesAtIndex(_ index: Int) -> Void {
        let imageManager = SDWebImageManager.shared()
        
        // free up memory for the lefter image
        
        let lefterLeftIndex = index - 2
        
        if photos.indices.contains(lefterLeftIndex) {
            photos[lefterLeftIndex].image = photos[lefterLeftIndex].smallImage
            photos[lefterLeftIndex].isLargeImageLoaded = false
            if let photosViewController = photosViewController {
                photosViewController.updateImage(for: photos[lefterLeftIndex])
            }
        }
        
        let righterRightIndex = index + 2
        
        if photos.indices.contains(righterRightIndex) {
            photos[righterRightIndex].image = photos[righterRightIndex].smallImage
            photos[righterRightIndex].isLargeImageLoaded = false
            if let photosViewController = photosViewController {
                photosViewController.updateImage(for: photos[righterRightIndex])
            }
        }
        
        // load the base image
        
        if !photos[index].isLargeImageLoaded {
            let url = photos[index].largeImageUrl!
            
            _ = imageManager?.downloadImage(with: URL(string: url), options: SDWebImageOptions.highPriority, progress: nil, completed: { (image: UIImage?, error: Error?, cacheType: SDImageCacheType,finished: Bool, imageURL: URL?) -> Void in
                if image != nil {
                    self.photos[index].image = image
                    self.photos[index].isLargeImageLoaded = true
                    if let photosViewController = self.photosViewController {
                        photosViewController.updateImage(for: self.photos[index])
                    }
                }
            })
        }
        
        // load the lefter image
        
        let leftIndex = index - 1
        
        if photos.indices.contains(leftIndex) && !photos[leftIndex].isLargeImageLoaded {
            let leftUrl = photos[leftIndex].largeImageUrl!
            
            _ = imageManager?.downloadImage(with: URL(string: leftUrl), options: SDWebImageOptions.highPriority, progress: nil, completed: { (image: UIImage?, error: Error?, cacheType: SDImageCacheType, finished: Bool, imageURL: URL?) -> Void in
                if image != nil {
                    self.photos[leftIndex].image = image
                    self.photos[leftIndex].isLargeImageLoaded = true
                    if let photosViewController = self.photosViewController {
                        photosViewController.updateImage(for: self.photos[leftIndex])
                    }
                }
            })
        }
        
        // load righter image
        
        let rightIndex = index + 1
        
        if photos.indices.contains(rightIndex) && !photos[rightIndex].isLargeImageLoaded {
            let rightUrl = photos[rightIndex].largeImageUrl!
            
            _ = imageManager?.downloadImage(with: URL(string: rightUrl), options: SDWebImageOptions.highPriority, progress: nil, completed: { (image: UIImage?, error: Error?, cacheType: SDImageCacheType,finished: Bool, imageURL: URL?) -> Void in
                if image != nil {
                    self.photos[rightIndex].image = image
                    self.photos[rightIndex].isLargeImageLoaded = true
                    if let photosViewController = self.photosViewController {
                        photosViewController.updateImage(for: self.photos[rightIndex])
                    }
                }
            })
        }
    }
    
    // MARK: Action
    
    @IBAction func imageViewTaped(_ sender: UITapGestureRecognizer) {
        let photo = NewsArticlePhoto(image: imageView.image, smallImageUrl: article?.imageUrl, isSmallImage: false, description: nil)
        photosViewController = NYTPhotosViewController(photos: [photo])
        photosViewController?.delegate = self
        if imageView.image == nil {
            imageView.sd_setImage(with: URL(string: photo.largeImageUrl!), completed: { (image: UIImage?, error: Error?, cacheType: SDImageCacheType, imageURL: URL?) -> Void in
                photo.image = image
                photo.isLargeImageLoaded = true
                
                if let photosViewController = self.photosViewController {
                    photosViewController.updateImage(for: photo)
                }
            })
        }
        present(photosViewController!, animated: true, completion: nil)
    }
    
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        UIApplication.shared.openURL(url)
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
