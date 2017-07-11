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
    
    public var cellRef: [String: ChatTableViewCell] = [:]

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

        setNotificationObservers()
    }
    deinit {
        if let refHandle = userRefHandle {
            userRef.removeObserver(withHandle: refHandle)
        }
    }
    
    private func setNotificationObservers() {
        let notifRef = userRef.child(self.senderId).child("notifications")
        for user in users {
            let userNotifRef = notifRef.child(user.key)
            userNotifRef.removeAllObservers()
            userNotifRef.observe(.value, with: { (snapshot) in
                self.setCellNotification(forUser: user, snapshot)
            })
        }
    }
    
    private func setCellNotification(forUser user: User, _ snapshot: FIRDataSnapshot, _ forCell: ChatTableViewCell? = nil) {
        if let value = snapshot.value as? Int {
            var cell = self.cellRef[user.key]
            
            if let cellParam = forCell {
                cell = cellParam
            }
            cell?.notificationNumber.text = value.description
            cell?.notificationNumber.alpha = 1.0
            cell?.notificationIcon.alpha = 1.0
            self.cellRef[user.key] = cell
            
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

        let user = users[indexPath.row]
        
        
        let departmentName = user.name

        let notificationsRef = userRef.child(self.senderId).child("notifications")
        
        cell.configureCell(title: departmentName!)

        // Set notification if there is an notification index at Users's notification table
        notificationsRef.child(user.key).observe(.value, with: { (snapshot) in
            self.setCellNotification(forUser: user, snapshot, cell)
        })
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = users[(indexPath as NSIndexPath).row]

        let cellChat = tableView.cellForRow(at: indexPath) as? ChatTableViewCell


        if let cell = cellChat {
            if cell.notificationIcon.alpha == 1.0 {
                userRef.child(self.senderId).child("notifications").child(user.key).removeValue()
                cell.notificationIcon.alpha = 0
                cell.notificationNumber.alpha = 0
                userRef.child(self.senderId).child("notifications").child(user.key).removeAllObservers()
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
