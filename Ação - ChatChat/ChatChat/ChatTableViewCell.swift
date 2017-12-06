//
//  ChatTableViewCell.swift
//  Ação
//
//  Created by Miguel Asipavicins on 11/01/17.
//  Copyright © 2017 Razeware LLC. All rights reserved.
//

import UIKit

class ChatTableViewCell: UITableViewCell {

    @IBOutlet weak var notificationNumber: UILabel!
    @IBOutlet weak var iconImg: UIImageView!
    @IBOutlet weak var departmentName: UILabel!
    @IBOutlet weak var advanceIconImg: UIImageView!
    @IBOutlet weak var departmentAvailability: UILabel!
    
    public var cellDepartmentId: String?
    
    @IBOutlet weak var notificationIcon: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        print("awake")
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func configureCell(title: String, deptAvailability: String){
        
        self.departmentName.text = title
        
        if title == "Contábil"{
            iconImg.image = UIImage(named: "contabil")
        }else if title == "Pessoal"{
            iconImg.image = UIImage(named: "pessoal")
        }else if title == "Fiscal"{
            iconImg.image = UIImage(named: "fiscal")
        }else if title == "Societário"{
            iconImg.image = UIImage(named: "societario")
        }else{
            print("Existe algum departamento a mais que departamento")
        }
        
        self.departmentAvailability.text = deptAvailability
    }
    
}
