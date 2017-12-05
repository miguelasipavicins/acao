//
//  NewsTableViewCell.swift
//  Ação
//
//  Created by Miguel Asipavicins on 19/12/16.
//  Copyright © 2016 Razeware LLC. All rights reserved.
//

import UIKit

class NewsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var detailsLbl: UILabel!
    @IBOutlet weak var dateLbl: UILabel!
    @IBOutlet weak var backgroungCardView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func layoutSubviews() {
        backgroungCardView.layer.masksToBounds = false
        backgroungCardView.alpha = 1
        backgroungCardView.layer.cornerRadius = 10
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureCell(title: String, description: String, date: String){

        titleLbl.text = title
        detailsLbl.text = description
        dateLbl.text = date
    }
    

}
