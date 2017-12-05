//
//  User.swift
//  ChatChat
//
//  Created by Miguel Asipavicins on 11/12/16.
//  Copyright © 2016 Razeware LLC. All rights reserved.
//

class User {

    let email: String!
    let key: String!
    let name: String!
    let type: String!

    init(email: String, key: String, name: String, type: String) {
        self.email = email
        self.key = key
        self.name = name
        self.type = type
    }

}
