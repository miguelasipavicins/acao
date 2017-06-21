//
//  NewsDetailsViewController.swift
//  ChatChat
//
//  Created by Miguel Asipavicins on 26/01/17.
//  Copyright © 2017 Razeware LLC. All rights reserved.
//

import UIKit
import Foundation

class NewsDetailsViewController: UIViewController {

    //MARK: Properties
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var textLbl: UILabel!
    
    var newsTitle: String!
    var newsText: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        // Do any additional setup after loading the view.
    }
    
    func configureView(){
        titleLbl.text = newsTitle
        textLbl.text = newsText
    }
    
}
