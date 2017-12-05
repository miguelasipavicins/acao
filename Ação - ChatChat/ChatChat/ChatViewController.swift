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
import MobileCoreServices

class ChatViewController: JSQMessagesViewController {
    
    var messages = [JSQMessage]()
    var chatIdentifier: String?
    
    lazy var outgoingBubbleImageView: JSQMessagesBubbleImage = self.setupOutgoingBubble()
    lazy var incomingBubbleImageView: JSQMessagesBubbleImage = self.setupIncomingBubble()
    
    //Variables used for photo storage
    lazy var storageRef: FIRStorageReference = FIRStorage.storage().reference(forURL: "gs://acao-f519d.appspot.com")
    private let imageURLNotSetKey = "NOTSET"
    private var photoMessageMap = [String: JSQPhotoMediaItem]()
    private var PDFMessageMap = [String: JSQMediaItem]()
    private var updatedMessageRefHandle: FIRDatabaseHandle?
    
    
    private lazy var chatsRef: FIRDatabaseReference = FIRDatabase.database().reference().child("chat-messages")
    private var chatsRefHandle: FIRDatabaseHandle?
    private lazy var usersRef = FIRDatabase.database().reference().child("users")
    private var newMessageRefHandle: FIRDatabaseHandle?
    
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
        super.viewDidAppear(animated)
        //collectionView.collectionViewLayout.springinessEnabled = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabBarController?.tabBar.alpha = 0
        
        // No avatars
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        
        //self.inputToolbar.contentView.leftBarButtonItem = nil
        automaticallyScrollsToMostRecentMessage = true
        
        checkForUserChatsWithDepartment()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.alpha = 1
        // Removes the Firebase Notification array for the current chat and user
        removeChatNotification()
        
    }
    
    
    private func removeChatNotification() {
        usersRef.child(senderId).child("notifications").child((user?.key)!).removeValue()
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
 
    
    private func addMessage(withId id: String, name: String, text: String, date: Date) {
        
        if let message = JSQMessage(senderId: id, senderDisplayName: name, date: date, text: text) {
            messages.append(message)
        }
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
    
        let message = messages[indexPath.item]
        var color: UIColor = .darkGray

        if message.senderId == self.senderId {
            cell.cellTopLabel.textAlignment = .right
            cell.cellTopLabel.textInsets = .init(top: 0, left: 0, bottom: 0, right: 20)
            color = .white
        }else{
            cell.cellTopLabel.textAlignment = .left
            cell.cellTopLabel.textInsets = .init(top: 0, left: 20, bottom: 0, right: 0)
        }
        
        cell.textView?.textColor = color

        let attributes : [String:AnyObject] = [NSAttributedStringKey.foregroundColor.rawValue: color, NSAttributedStringKey.underlineStyle.rawValue: 1 as AnyObject]

        cell.textView?.linkTextAttributes = attributes
        
        return cell
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        var dateFormatPTBR = ""
        if let date = messages[indexPath.row].date {
        
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss +zzzz"
        
            let dateFormatted = dateFormatter.date(from: date.description)
        
            var formatString = "HH:mm:ss"

            if !isMessageFromToday(messageDate: date) {
                formatString.append(" dd/MM/yyyy")
            }
        
            dateFormatter.dateFormat = formatString

            dateFormatPTBR = dateFormatter.string(from: dateFormatted!)
        }
        return NSAttributedString(string: dateFormatPTBR)
    }

    private func isMessageFromToday(messageDate: Date) -> Bool {
        let today = Date()

        let calendar = Calendar.current

        let todayDay = calendar.component(.day, from: today)
        let todayMonth = calendar.component(.month, from: today)

        let messageDay = calendar.component(.day, from: messageDate)
        let messageMonth = calendar.component(.month, from: messageDate)

        return (todayDay == messageDay) && (todayMonth == messageMonth)
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAt indexPath: IndexPath!) -> CGFloat {
        return 20
    }
    
    
    
    func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        let message = messages[indexPath.item]
        
        // Sent by me, skip
        if message.senderId == self.senderId {
            return CGFloat(0.0);
        }
        
        // Same as previous sender, skip
        if indexPath.item > 0 {
            let previousMessage = messages[indexPath.item - 1];
            if previousMessage.senderId == message.senderId {
                return CGFloat(0.0);
            }
        }
        
        return kJSQMessagesCollectionViewCellLabelHeightDefault
    }
    
    
    private func checkForUserChatsWithDepartment(){
        
        let userChatsReference: FIRDatabaseReference = FIRDatabase.database().reference().child("user-chatContacts:chat")
        userChatsReference.child(self.senderId).child(self.departmentId).observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
            let value = snapshot.value as? String
            if value != nil {
                self.chatIdentifier = value
                self.loadChatsWithSelectedDepartment()
            }else{
                self.createUserChatWithDepartment()
            }
        })
    }
    
    private func createUserChatWithDepartment() {
       
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
                        
                        let timeintervalDouble = chatData["timestamp"] as? Int64
                        let timeinterval = TimeInterval.init(exactly: timeintervalDouble! / 1000)
                        //timeinterval?.divide(by: 1000)
                        let date = Date(timeIntervalSince1970: timeinterval!)

                        self.addMessage(withId: id, name: name, text: text, date: date)
                        self.finishReceivingMessage()
                        //JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
                    }
                    //Este else foi implementado para imagens
                    else if let id = chatData["senderId"] as! String! {
                        if let photoURL = chatData["photoURL"] as! String! { // 1
                        // 2
                            if let mediaItem = JSQPhotoMediaItem(maskAsOutgoing: id == self.senderId) {
                                // 3
                                self.addPhotoMessage(withId: id, key: chatSnapshot.key, mediaItem: mediaItem)
                                // 4
                                if photoURL.hasPrefix("gs://") {
                                    self.fetchImageDataAtURL(photoURL, forMediaItem: mediaItem, clearsPhotoMessageMapOnSuccessForKey: nil)
                                }
                            }
                        }
                    
                        if let pdfURL = chatData["PDFUrl"] as? String {
                            if let mediaItem = JSQMediaItem(maskAsOutgoing: id == self.senderId) {
                                self.addPDFMessage(withId: id, key: chatSnapshot.key, mediaItem: mediaItem)
                                
                                if pdfURL.hasPrefix("gs://") {
                                    self.setPDFDownloadable(pdfURL, forMediaItem: mediaItem, clearsPDFMessageMapOnSuccessForKey: nil)
                                }
                            }
                        }
                        self.finishReceivingMessage()
            }
                // Se obtiver uma url de
            }
        )
        
        // We can also use the observer method to listen for
        // changes to existing messages.
        // We use this to be notified when a photo has been stored
        // to the Firebase Storage, so we can update the message data
        updatedMessageRefHandle = FIRDatabase.database().reference().child("chat-messages").child(self.chatIdentifier!).observe(.childChanged, with: { (snapshot) in
            let key = snapshot.key
            if let messageData = snapshot.value as? [String: Any] {// 1
                if let photoURL = messageData["photoURL"] as? String { // 2
                    // The photo has been updated.
                    if let mediaItem = self.photoMessageMap[key] { // 3
                        self.fetchImageDataAtURL(photoURL, forMediaItem: mediaItem, clearsPhotoMessageMapOnSuccessForKey: key) // 4
                    }
                }
            }
        })
    }
    
    
    // MARK: Envio de mensagens
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        
        //print(self.chatIdentifier)
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
        //print(messageItem)
        JSQSystemSoundPlayer.jsq_playMessageSentSound() // 4
        finishSendingMessage() // 5
    }
    
    
    //Send image
    func sendPhotoMessage() -> String? {
        let itemRef = self.chatsRef.child(self.chatIdentifier!).childByAutoId()
        let currentTimeInMilli = Int64(NSDate().timeIntervalSince1970 * 1000)
        let negativeCurrentTimeInMilli = currentTimeInMilli * (-1)

        let messageItem = [
            "photoURL": imageURLNotSetKey,
            "senderId": senderId!,
            "senderEmail": self.loggedUserEmail!,
            "timestamp": currentTimeInMilli
        ] as [String : Any]
        
        itemRef.setValue(messageItem)
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        finishSendingMessage()
        return itemRef.key
    }

    //Update message once you get a Firebase URL
    func setImageURL(_ url: String, forPhotoMessageWithKey key: String) {
        let itemRef = self.chatsRef.child(self.chatIdentifier!).child(key)
        itemRef.updateChildValues(["photoURL": url])
    }

    //Function to request alert picker view
    override func didPressAccessoryButton(_ sender: UIButton) {
//        let picker = UIImagePickerController()
//        picker.delegate = self as UIImagePickerControllerDelegate & UINavigationControllerDelegate
//        if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)) {
//            picker.sourceType = UIImagePickerControllerSourceType.camera
//        } else {
//            picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
//        }
//
//        present(picker, animated: true, completion:nil)
        
        let picker = UIImagePickerController()
        picker.delegate = self
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: {
            action in
            picker.sourceType = .camera
            self.present(picker, animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Galeria", style: .default, handler: {
            action in
            picker.sourceType = .photoLibrary
            self.present(picker, animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Documentos", style: .default, handler: {
            action in
            
            let importMenu = UIDocumentMenuViewController(documentTypes: [String(kUTTypePDF)], in: .import)
            importMenu.delegate = self
            importMenu.modalPresentationStyle = .formSheet
            self.present(importMenu, animated: true, completion: nil)
        }))
        
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    private func setPDFDownloadable(_ pdfURL: String, forMediaItem mediaItem: JSQMediaItem, clearsPDFMessageMapOnSuccessForKey key: String?) {
        if pdfURL == "NOTSET" {
            return
        }
        
        let storageRef = FIRStorage.storage().reference(forURL: pdfURL)
        
        let localURL = getDocumentsDirectory()
        
        
        let downloadTask = storageRef.write(toFile: localURL) { url, error in
            if let error = error {
                NSLog("Error downloading file")
                return
            }
            
            if let url = url {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    // Fallback on earlier versions
                }
            }
        }
    }
    
    //Fetchs the image from URL
    private func fetchImageDataAtURL(_ photoURL: String, forMediaItem mediaItem: JSQPhotoMediaItem, clearsPhotoMessageMapOnSuccessForKey key: String?) {
        // 1
        
        // ARRUMAR NOTSET
        if photoURL == "NOTSET" {
            return
        }

        let storageRef = FIRStorage.storage().reference(forURL: photoURL)
        // 2
        storageRef.data(withMaxSize: INT64_MAX){ (data, error) in
            if let error = error {
                print("Error downloading image data: \(error)")
                return
            }
            
            // 3
            storageRef.metadata(completion: { (metadata, metadataErr) in
                if let error = metadataErr {
                    print("Error downloading metadata: \(error)")
                    return
                }
                
                // 4
                if (metadata?.contentType == "image/gif") {
                    //AQUI PRECISA CORRIGIR
                    print("Its a gif")
                    mediaItem.image = UIImage.init(data: data!)
                    
                    
                } else {
                    mediaItem.image = UIImage.init(data: data!)
                }
                self.collectionView.reloadData()
                
                // 5
                guard key != nil else {
                    return
                }
                
                self.photoMessageMap.removeValue(forKey: key!)
            })
            
        }
    }
    
    func updateLatestMessageTimestamp(timeStamp: Int64){
        FIRDatabase.database().reference().child("user-chats-properties").child(self.departmentId).child(self.chatIdentifier!).child("latestMessageTimestamp").setValue(timeStamp)
    }
    
    //adds image to the message
    private func addPhotoMessage(withId id: String, key: String, mediaItem: JSQPhotoMediaItem) {
        if let message = JSQMessage(senderId: id, displayName: "", media: mediaItem) {
            messages.append(message)
            
            if (mediaItem.image == nil) {
                photoMessageMap[key] = mediaItem
            }
            
            collectionView.reloadData()
        }
    }
    
    private func addPDFMessage(withId id: String, key: String, mediaItem: JSQMediaItem) {
        if let message = JSQMessage(senderId: id, displayName: "", media: mediaItem) {
            messages.append(message)
            
//            if (mediaItem.mediaView() == nil) {
//                PDFMessageMap[key] = mediaItem
//            }
            
            collectionView.reloadData()
        }
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

// MARK: Image Picker Delegate
extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion:nil)
        self.tabBarController?.tabBar.alpha = 0
        
        // 1
        if let photoReferenceUrl = info[UIImagePickerControllerReferenceURL] as? URL {
            // Handle picking a Photo from the Photo Library
            // 2
            let assets = PHAsset.fetchAssets(withALAssetURLs: [photoReferenceUrl], options: nil)
            let asset = assets.firstObject
            
            // 3
            if let key = sendPhotoMessage() {
                // 4
                asset?.requestContentEditingInput(with: nil, completionHandler: { (contentEditingInput, info) in
                    let imageFileURL = contentEditingInput?.fullSizeImageURL
                    
                    // 5
                    let path = "\((FIRAuth.auth()?.currentUser?.uid)!)/\(Int(Date.timeIntervalSinceReferenceDate * 1000))/\(photoReferenceUrl.lastPathComponent)"
                    
                    // 6
                    self.storageRef.child(path).putFile(imageFileURL!, metadata: nil) { (metadata, error) in
                        if let error = error {
                            print("Error uploading photo: \(error.localizedDescription)")
                            return
                        }
                        // 7
                        self.setImageURL(self.storageRef.child((metadata?.path)!).description, forPhotoMessageWithKey: key)
                    }
                })
            }
        } else {
            // Handle picking a Photo from the Camera - TODO
            // 1
            let image = info[UIImagePickerControllerOriginalImage] as! UIImage
            // 2
            if let key = sendPhotoMessage() {
                // 3
                let imageData = UIImageJPEGRepresentation(image, 0.125)
                // 4
                let imagePath = FIRAuth.auth()!.currentUser!.uid + "/\(Int64(Date.timeIntervalSinceReferenceDate * 1000))/\(key).jpg"
                // 5
                let metadata = FIRStorageMetadata()
                metadata.contentType = "image/jpeg"
                // 6
                storageRef.child(imagePath).put(imageData!, metadata: metadata) { (metadata, error) in
                    if let error = error {
                        print("Error uploading photo: \(error)")
                        return
                    }
                    // 7
                    self.setImageURL(self.storageRef.child((metadata?.path)!).description, forPhotoMessageWithKey: key)
                }
            }
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
        self.tabBarController?.tabBar.alpha = 0
    }
}

extension ChatViewController: UIDocumentMenuDelegate, UIDocumentPickerDelegate {

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        // Create a reference to the file you want to upload
        uploadDocument(with: url)
    }
    
    func setDocumentFirebaseURL(_ url: String, forFireBaseURL key: String) {
        let itemRef = self.chatsRef.child(self.chatIdentifier!).child(key)
        itemRef.updateChildValues(["PDFUrl": url])
    }
    
    func sendPDFMessage() -> String? {
        let itemRef = self.chatsRef.child(self.chatIdentifier!).childByAutoId()
        let currentTimeInMilli = Int64(NSDate().timeIntervalSince1970 * 1000)
        
        let messageItem = [
            "PDFUrl": "NOTSET",
            "senderId": senderId!,
            "senderEmail": self.loggedUserEmail!,
            "timestamp": currentTimeInMilli
            ] as [String : Any]
        
        itemRef.setValue(messageItem)
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        finishSendingMessage()
        return itemRef.key
    }
    
    private func uploadDocument(with url: URL) {
        if let user = self.user {
            let documentRef = storageRef.child("documents/" + user.key + Int64(Date.timeIntervalSinceReferenceDate * 1000).description)
            
            if let messageURL = sendPDFMessage() {
                print("PDF MESSAGE URL: \(messageURL)")
                let _ = documentRef.putFile(url, metadata: nil) {
                    metadata, error in
                    if let error = error {
                        NSLog(error.localizedDescription)
                        return
                    }
                        // Metadata contains file metadata such as size, content-type, and download URL.
                    if let downloadURL = metadata!.downloadURL() {
                        self.setDocumentFirebaseURL(downloadURL.description, forFireBaseURL: messageURL.description)
                    }
                }
            }
        }
    }
    
    @available(iOS 8.0, *)
    public func documentMenu(_ documentMenu: UIDocumentMenuViewController, didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
    
        documentPicker.delegate = self
        present(documentPicker, animated: true, completion: nil)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("we cancelled")
        controller.dismiss(animated: true, completion: nil)
        self.tabBarController?.tabBar.alpha = 0
    }
}
