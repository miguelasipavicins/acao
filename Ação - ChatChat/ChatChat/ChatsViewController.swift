//
//  ChatsViewController.swift
//  ChatChat
//
//  Created by Miguel Asipavicins on 13/08/17.
//  Copyright © 2017 Razeware LLC. All rights reserved.
//

import Foundation
import Firebase

class ChatsViewController: UITableViewController {
    
    private lazy var currentUserChatsReference: FIRDatabaseReference = FIRDatabase.database().reference().child("user-chats-properties")
    
    //Logged user preferences
    var senderId: String!
    var loggedUserEmail: String!
    var loggedUserName: String!
    var loggedUserCompany: String!
    var loggedUserType: String!
    
    var chats: [Chat] = []
    
    override func viewDidLoad() {
        getLoggedUserPreferences()
        subscribeForUserChatsUpdates()
    }
    
    func getLoggedUserPreferences(){
        self.senderId = FIRAuth.auth()?.currentUser?.uid
        self.loggedUserEmail = FIRAuth.auth()?.currentUser?.email
        FIRDatabase.database().reference().child("users").child(self.senderId).observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
            let loggedUserPreferences = snapshot.value as! Dictionary<String, AnyObject>
            if let loggedUserName = loggedUserPreferences["name"] as! String!,
                let loggedUserCompany = loggedUserPreferences["company"] as! String!, let loggedUserType = loggedUserPreferences["company"] as! String!{
                self.loggedUserName = loggedUserName
                self.loggedUserCompany = loggedUserCompany
                self.loggedUserType = loggedUserType
                print("Usuário \(self.loggedUserName!), da empresa \(self.loggedUserCompany!) logado com sucesso através do email \(self.loggedUserEmail!)")
            }else{
                print("Não foi possível determinar o usuário, algum dado não foi cadastrado")
            }
        })
    }
    
    func subscribeForUserChatsUpdates(){
        currentUserChatsReference.child(self.senderId).queryOrdered(byChild: "latestMessageTimestamp").observe(.childAdded, with: { (snapshot) in
            
           let chatData = snapshot.value as! Dictionary<String, AnyObject>
            if let contactCompany = chatData["contactCompany"] as! String!, let contactId = chatData["contactId"] as! String!, let latestMessageTimestamp = chatData["latestMessageTimestamp"] as! Int64!, let name = chatData["name"] as! String!, let unreadMessageCount = chatData["unreadMessageCount"] as! Int!, let key = snapshot.key as String! {
               
                self.chats.append(Chat(contactCompany: contactCompany, key: key, name: name, contactId: contactId, unreadMessageCount: unreadMessageCount, latestMessageTimestamp: latestMessageTimestamp))
                
                self.tableView.reloadData()
                
            }
            
        })
    }
    
    
    // MARK: TableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chats.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "chatInfoCell", for: indexPath)
        
        cell.detailTextLabel?.text = "miguel"
        
        return cell
        
    }

}
