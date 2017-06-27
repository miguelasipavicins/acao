/*
 * Copyright (c) 2015 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import Firebase
import Photos
import JSQMessagesViewController

class ChatViewController: JSQMessagesViewController {
    
    var messages = [JSQMessage]()
    var chatIdentifier: String?
    
    lazy var outgoingBubbleImageView: JSQMessagesBubbleImage = self.setupOutgoingBubble()
    lazy var incomingBubbleImageView: JSQMessagesBubbleImage = self.setupIncomingBubble()
    
    //private lazy var userChatsRef: FIRDatabaseReference = FIRDatabase.database().reference().child("user-chatContacts:chat")
    private lazy var chatsRef: FIRDatabaseReference = FIRDatabase.database().reference().child("chat-messages")
    private var chatsRefHandle: FIRDatabaseHandle?
    
    //Identifica o canal com o qual será feito o Chat
    var departmentId: String!
    
    //Identifica o usuário que está logado
    var loggedUserEmail: String!
    var loggedUserName: String!
    var loggedUserCompany: String!
    
    var user: User? {
        didSet {
            title = user?.name
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Preparação para futura função de ligar
        //navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Ligar", style: .plain, target: self, action: #selector(handleCall))
        
        // No avatars
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        
        self.inputToolbar.contentView.leftBarButtonItem = nil
        
        checkForUserChatsWithDepartment()
    }
    
    func handleCall(){
        //Adicionar função de ligar para o departamento
        }
    
    // MARK: Collection view methods (Bubbles setup)
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    private func setupOutgoingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    }
    
    private func setupIncomingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]
        if message.senderId == self.senderId {
            return outgoingBubbleImageView
        } else {
            return incomingBubbleImageView
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    private func addMessage(withId id: String, name: String, text: String) {
        if let message = JSQMessage(senderId: id, displayName: name, text: text) {
            messages.append(message)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        let message = messages[indexPath.item]
        
        if message.senderId == self.senderId {
            cell.textView?.textColor = UIColor.white
        }else{
            cell.textView?.textColor = UIColor.darkGray
        }
        return cell
    }
    
    
    private func checkForUserChatsWithDepartment(){
        
        let userChatsReference: FIRDatabaseReference = FIRDatabase.database().reference().child("user-chatContacts:chat")
        userChatsReference.child(self.senderId).child(self.departmentId).observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
            let value = snapshot.value as? String
            if value != nil {
                self.chatIdentifier = value
                print("O identificador de mensagem é: \(self.chatIdentifier)")
                self.loadChatsWithSelectedDepartment()
            }else{
                self.createUserChatWithDepartment()
            }
            
        })
        
    }
    
    private func createUserChatWithDepartment(){
       
        print("Não há mensagens para este canal ainda!")
        let chatPropertiesRef = FIRDatabase.database().reference().child("user-chats-properties")
        let chatKey = chatPropertiesRef.child(self.senderId!).childByAutoId().key
        self.chatIdentifier = chatKey
        
        
        //Cria as propriedas do chat do usuário logado para o departamento
        let chatPropertiesTo = [
            //"contactCompany": self.loggedUserCompany,
            "contactId": self.departmentId!,
            "latestMessageTimestamp": 0,
            "name": self.user?.name,
            "unreadMessageCount": 0
            ] as [String : Any]
        
        chatPropertiesRef.child(self.senderId).child(chatKey).setValue(chatPropertiesTo)
        
        //Cria as propriedas do chat do departamento para o usuário logado
        let chatPropertiesFrom = [
            "contactCompany": self.loggedUserCompany,
            "contactId": self.senderId!,
            "latestMessageTimestamp": 0,
            "name": self.loggedUserName,
            "unreadMessageCount": 0
            ] as [String : Any]
        
        chatPropertiesRef.child(self.departmentId).child(chatKey).setValue(chatPropertiesFrom)
        
        let userChatContactsChatRef = FIRDatabase.database().reference().child("user-chatContacts:chat")
        userChatContactsChatRef.child(self.senderId).child(self.departmentId).setValue(chatKey)
        userChatContactsChatRef.child(self.departmentId).child(self.senderId).setValue(chatKey)
        
        print("Criado chat do usuário!")
        
        self.loadChatsWithSelectedDepartment()
        
    }
    

    private func loadChatsWithSelectedDepartment() {
        
        FIRDatabase.database().reference().child("chat-messages").child(self.chatIdentifier!).observe(.childAdded, with: { (chatSnapshot) in
                let chatData = chatSnapshot.value as! Dictionary<String, AnyObject>
            
                    if let text = chatData["text"] as? String, let id = chatData["senderId"] as? String, let name = chatData["senderEmail"] as? String {
                        self.addMessage(withId: id as! String, name: name, text: text)
                        self.finishReceivingMessage()
                        JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
                    }
            }
        )
    }
    
    
    // MARK: Envio de mensagens
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        
        print(self.chatIdentifier)
        let itemRef = self.chatsRef.child(self.chatIdentifier!).childByAutoId()
        let currentTimeInMilli = Int64(NSDate().timeIntervalSince1970 * 1000)
        let negativeCurrentTimeInMilli = currentTimeInMilli * (-1)
        print("O timestamp negativo ficou? \(negativeCurrentTimeInMilli)")
        
        //O Timestamp nesta parte permanece positivo
        let messageItem = [
            "senderId": self.senderId!,
            "senderEmail": self.loggedUserEmail!,
            "text": text!,
            "timestamp": currentTimeInMilli
            ] as [String : Any]
        
        //Inclui a mensagem enviada, com um ID aleatório
        itemRef.setValue(messageItem)
        
        updateLatestMessageTimestamp(timeStamp: negativeCurrentTimeInMilli)
        incrementUnreadMessageCount()
        print(messageItem)
        JSQSystemSoundPlayer.jsq_playMessageSentSound() // 4
        finishSendingMessage() // 5
        /**
         https://fcm.googleapis.com/fcm/send

         */
        
        // SEND PUSH NOTIFICATION ON GOOGLE.APIS.COM
        
    }
    
    func updateLatestMessageTimestamp(timeStamp: Int64){
        FIRDatabase.database().reference().child("user-chats-properties").child(self.departmentId).child(self.chatIdentifier!).child("latestMessageTimestamp").setValue(timeStamp)
    }
    
    func incrementUnreadMessageCount(){
        let chatPropertiesRef = FIRDatabase.database().reference().child("user-chats-properties").child(self.departmentId).child(self.chatIdentifier!).child("unreadMessageCount")
        chatPropertiesRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if let unreadMessageCount = snapshot.value as? Int{
                chatPropertiesRef.setValue(unreadMessageCount + 1)
            }else{
                print("Erro ao localizar última contagem de mensagens não lidas")
            }
        })
    }
    
}
