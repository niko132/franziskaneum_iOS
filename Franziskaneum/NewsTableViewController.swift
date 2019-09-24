//
//  NewsTableViewController.swift
//  Franziskaneum
//
//  Created by Niko Kirste on 22.01.16.
//  Copyright © 2016 Franziskaneum. All rights reserved.
//

import UIKit
import SDWebImage

class NewsTableViewController: UITableViewController {
    
    let newsManager = NewsManager.instance
    var news: [NewsData]?
    
    var activityIndicatorView: UIActivityIndicatorView!
    
    var completionHandler: ((_ news: [NewsData]?, _ error: FranziskaneumError?) -> Void)!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 199.0
        
        self.refreshControl?.addTarget(self, action: #selector(NewsTableViewController.handleRefresh), for: .valueChanged)
        
        completionHandler = { (news, error) in
            DispatchQueue.main.async {
                self.handleLoadingResult(news, error: error)
            }
        }
        
        tableView.estimatedRowHeight = 188.0
        
        activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        activityIndicatorView.color = UIColor.franziskaneum
        tableView.backgroundView = activityIndicatorView
        activityIndicatorView.hidesWhenStopped = true
    }
	
	override func viewWillAppear(_ animated: Bool) {
		if news == nil {
			startRefreshing()
			newsManager.getNews(false, completionHandler: completionHandler)
		}
	}
	
	func startRefreshing() {
		if let news = news, !news.isEmpty {
			refreshControl?.beginRefreshing()
		} else {
			activityIndicatorView.startAnimating()
		}
	}
	
	func stopRefreshing() {
		refreshControl?.endRefreshing()
		activityIndicatorView.stopAnimating()
	}
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func didMove(toParentViewController parent: UIViewController?) {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func handleRefresh() {
        newsManager.getNews(true, completionHandler: completionHandler)
    }
    
    func handleLoadingResult(_ news: [NewsData]?, error: FranziskaneumError?) {
        stopRefreshing()
        
        if let news = news {
            self.news = news
            self.tableView.reloadData()
        } else if let error = error {
            if self.isVisible {
                let message = error.description()
                
                // alert the user
                let alert = UIAlertController(title: "Fehler", message: message, preferredStyle: .alert)
                alert.view.tintColor = UIColor.franziskaneum
                alert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "Erneut Versuchen", style: .default, handler: { (action: UIAlertAction) in
                    self.newsManager.getNews(true, completionHandler: self.completionHandler)
                    self.startRefreshing()
                }))
                
                // needs to be called otherwise warning
                alert.view.setNeedsLayout()
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let news = news {
            if newsManager.olderPostsAvailabe() {
                return news.count + 1
            } else {
                return news.count
            }
        }
        
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if newsManager.olderPostsAvailabe() && (indexPath as NSIndexPath).row == news!.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "NewsTableViewCellOlderPosts", for: indexPath) as! NewsOlderPostsTableViewCell
            cell.loadingIndicator.startAnimating()
            return cell
        } else {
            let article = news![(indexPath as NSIndexPath).row]
            
            if let imageUrl = article.imageUrl , !imageUrl.isEmpty {
                let cell = tableView.dequeueReusableCell(withIdentifier: "NewsImageTableViewCell", for: indexPath) as! NewsImageTableViewCell
                
                cell.titleLabel.text = article.title
                cell.contentLabel.attributedTextLabelFont = article.previewContent
                
                if let image = article.baseImage {
                    cell.imageImageView.image = image
                } else {
                    cell.layoutIfNeeded()
                    
                    cell.imageImageView.sd_setImage(with: URL(string: imageUrl), completed: { (image: UIImage?, error: Error?, cacheType: SDImageCacheType, imageURL: URL?) -> Void in
                        article.baseImage = image
                        
                        if let cell = tableView.cellForRow(at: indexPath) as? NewsImageTableViewCell {
                            cell.imageImageView.maskCircle()
                        }
                    })
                }
                
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "NewsTableViewCell", for: indexPath) as! NewsTableViewCell
                
                cell.titleLabel.text = article.title
                cell.contentLabel.attributedTextLabelFont = article.previewContent
                
                return cell
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? NewsImageTableViewCell {
            cell.imageImageView.maskCircle()
        } else if indexPath.row == news!.count {
            newsManager.loadOlderPosts(completionHandler)
        }
    }
    
    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? NewsImageTableViewCell {
            cell.imageImageView.image = nil
        }
    }
    
    /**
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).row == news!.count {
            newsManager.loadOlderPosts(completionHandler)
        }
    }
 **/
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
     if editingStyle == .Delete {
     // Delete the row from the data source
     tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
     } else if editingStyle == .Insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let selectedCell = sender as? UITableViewCell {
            let articleViewController = segue.destination as! NewsArticleViewController
            let indexPath = self.tableView.indexPath(for: selectedCell)!
            if let news = news , (indexPath as NSIndexPath).row < news.count {
                let article = news[(indexPath as NSIndexPath).row]
                articleViewController.article = article
            }
        }
    }
    
}
