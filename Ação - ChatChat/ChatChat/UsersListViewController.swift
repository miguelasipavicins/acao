//
//  UsersListViewController.swift
//  ChatChat
//
//  Created by Miguel Asipavicins on 11/12/16.
//  Copyright © 2016 Razeware LLC. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class UsersListViewController: UITableViewController{
    
    // MARK: Properties
    var senderDisplayName: String?
    var users: [User] = []
    private lazy var userRef: FIRDatabaseReference = FIRDatabase.database().reference().child("users")
    private var userRefHandle: FIRDatabaseHandle?
    
    public var notificationsRef: [FirebaseRef] = []
    
    //Logged user preferences
    var senderId: String!
    var loggedUserEmail: String!
    var loggedUserName: String!
    var loggedUserCompany: String!
    var loggedUserType: String!
    
    override func viewDidLoad() {
        getLoggedUserPreferences()
        observeUsers()
        
        // If have Firebase Instance ID Token, retreive it and save on current user table
        saveFCMToken()

    }

    private func saveFCMToken() {
        if let refreshedToken = FIRInstanceID.instanceID().token() {
            userRef.child(senderId).child("fcm_token").setValue(refreshedToken)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = false
        
        if notificationsRef.count >= 1 {
            for index in 0...notificationsRef.count - 1 {
                self.setNotification(forCell: notificationsRef[index].cell, atIndex: index)
            }
        }
    }
    deinit {
        if let refHandle = userRefHandle {
            userRef.removeObserver(withHandle: refHandle)
        }
    }

    // MARK: TableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ExistingUser") as! ChatTableViewCell
        
        let departmentName = users[indexPath.row].name
        
        cell.configureCell(title: departmentName!)

        // Set notification if there is an notification index at Users's notification table
        notificationsRef.append(setNotification(forCell: cell, atIndex: indexPath.row))
        
        
        return cell
    }
    
    private func setNotification(forCell cell: ChatTableViewCell, atIndex index: Int) -> FirebaseRef{
        let notificationRef = userRef.child(self.senderId).child("notifications").observe(.value, with: { (snapshot) in
            if let notificationList = snapshot.value as? [String: Int] {
                if self.users[index].key == notificationList.first?.key {
                    cell.notificationIcon.alpha = 1.0
                }
            }
        })
        
        return FirebaseRef(cell: cell, key: cell.departmentName.text!, uid: notificationRef)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = users[(indexPath as NSIndexPath).row]

        let cellChat = tableView.cellForRow(at: indexPath) as? ChatTableViewCell

        
        if let cell = cellChat {
            print(self.notificationsRef)
            if cell.notificationIcon.alpha == 1.0 {
                userRef.child(self.senderId).child("notifications").child(user.key).removeValue()
                cell.notificationIcon.alpha = 0
                
                if let notifRefUId = getFirebaseRef(cell.departmentName.text!) {
                    userRef.child(self.senderId).child("notifications").removeObserver(withHandle: notifRefUId)
                }
            }
        }

        self.performSegue(withIdentifier: "ShowChat", sender: user)
    }
    
    private func getFirebaseRef(_ text: String) -> UInt? {
        for notifRef in self.notificationsRef {
            if notifRef.key == text {
                return notifRef.uid
            }
        }
        return nil
    }

    // MARK: Firebase related methods
    private func observeUsers() {
        //Use the observe method to listen for new users being written to the Firebase DB
        userRefHandle = userRef.queryOrdered(byChild: "type").queryEqual(toValue: "acao").observe(.childAdded, with: { (snapshot) in
            let departmentData = snapshot.value as! Dictionary<String, AnyObject>
            if let name = departmentData["name"] as! String!, let email = departmentData["email"] as! String!, let type = departmentData["type"] as! String!, let key = snapshot.key as String!{
                self.users.append(User(email: email, key: key, name: name, type: type))
                self.tableView.reloadData()
            }else{
                print("Erro ao popular o table view")
            }
        })
    }
    
    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let selectedDepartment = sender as? User {
            let chatVc = segue.destination as! ChatViewController
            chatVc.senderDisplayName = selectedDepartment.name
            chatVc.user = selectedDepartment
            chatVc.departmentId = selectedDepartment.key
            chatVc.senderId = self.senderId
            chatVc.loggedUserEmail = self.loggedUserEmail
            chatVc.loggedUserName = self.loggedUserName
            chatVc.loggedUserCompany = self.loggedUserCompany
            self.tabBarController?.tabBar.isHidden = true
        }
        
    }
    
    
    //MARK: Volta para a tela de login
    @IBAction func signoutButtonPressed(_ sender: Any) {
        
        do {
            try FIRAuth.auth()!.signOut()
            dismiss(animated: true, completion: nil)
        } catch {
            
        }
    }
    
    func getLoggedUserPreferences(){
        self.senderId = FIRAuth.auth()?.currentUser?.uid
        self.loggedUserEmail = FIRAuth.auth()?.currentUser?.email
        FIRDatabase.database().reference().child("users").child(self.senderId).observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
            let loggedUserPreferences = snapshot.value as! Dictionary<String, AnyObject>
            print(loggedUserPreferences)
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
}
