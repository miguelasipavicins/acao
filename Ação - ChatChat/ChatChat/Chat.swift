//
//  Chat.swift
//  ChatChat
//
//  Created by Miguel Asipavicins on 13/08/17.
//  Copyright © 2017 Razeware LLC. All rights reserved.
//


import Foundation

class Chat {
    
    var key: String!
    var name: String!
    var contactId: String!
    var contactCompany: String!
    var unreadMessageCount: Int!
    var latestMessageTimestamp: Int64!
    
    init(contactCompany: String, key: String, name: String, contactId: String, unreadMessageCount: Int, latestMessageTimestamp: Int64) {
        self.contactCompany = contactCompany
        self.key = key
        self.name = name
        self.contactId = contactId
        self.unreadMessageCount = unreadMessageCount
        self.latestMessageTimestamp = latestMessageTimestamp
    }
    
}
