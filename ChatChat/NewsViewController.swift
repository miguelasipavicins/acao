//
//  NewsViewController.swift
//  Ação
//
//  Created by Miguel Asipavicins on 13/12/16.
//  Copyright © 2016 Razeware LLC. All rights reserved.
//

import UIKit
import Firebase

class NewsViewController: UITableViewController {

    //MARK: Properties
    var news = [News]()
    var selectedIndex: NSInteger = -1
    
    
    //MARK: Firebase references
    private lazy var newsRef: FIRDatabaseReference = FIRDatabase.database().reference().child("news")
    private var newsRefHandle: FIRDatabaseHandle?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        observeNews()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.news.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! NewsTableViewCell
        cell.titleLbl.text = news[indexPath.row].title
        cell.detailsLbl.text = news[indexPath.row].text
        cell.dateLbl.text = news[indexPath.row].date
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let news = self.news[(indexPath as NSIndexPath).row]
        self.performSegue(withIdentifier: "ShowNews", sender: news)
    
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let selectedNews = sender as? News {
            let newsVc = segue.destination as! NewsDetailsViewController
            let newsTitle = selectedNews.title!
            let newsText = selectedNews.text!
            newsVc.newsText = newsText
            newsVc.newsTitle = newsTitle
            
        }else{
            print("Não há notícias disponíveis")
        }
    }
    
    func observeNews() {
        newsRefHandle = newsRef.observe(.childAdded, with: { (snapshot) in
            let newsData = snapshot.value as! Dictionary<String, AnyObject>
            if let date = newsData["date"] as! String!, let text = newsData["text"] as! String!, let title = newsData["title"] as! String! {
                self.news.append(News(date: date, text: text, title: title))
                self.tableView.reloadData()
            }else{
                print("Erro ao popular o table view")
            }
        })
        
    }

}
