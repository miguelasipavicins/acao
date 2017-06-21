//
//  News.swift
//  Ação
//
//  Created by Miguel Asipavicins on 13/12/16.
//  Copyright © 2016 Razeware LLC. All rights reserved.
//

import Foundation

class News {
    
    let date: String?
    let text: String!
    let title: String!
    
    init(date: String, text: String, title: String){
        self.date = date
        self.text = text
        self.title = title
    }
    
}
