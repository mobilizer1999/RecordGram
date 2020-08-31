//
//  MessagesClient.swift
//  RecordGram
//
//  Created by Nicolas Gonzalez on 12/9/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import Firebase

class MessagesClient: Client {
    static let shared = MessagesClient()

    var ref: DatabaseReference = Database.database().reference()
    var recipient: String!
    lazy var conversationRef: DatabaseReference = ref.child("conversations")
    var currentChatRef: DatabaseReference!
    var currentConversationRef: DatabaseReference!

    func setup(uuid: String) {
        recipient = uuid
        var uuids = [uuid, self.uuid()]
        uuids.sort()
        let id = uuids.joined(separator: "_")
        currentChatRef = ref.child("messages").child(id)
        currentConversationRef = conversationRef.child(id)
    }

    func send(message: String) -> Message {
        let date = Date()
        let timestamp = date.timeIntervalSince1970
        let uuid = self.uuid()
        let messageRef = currentChatRef.childByAutoId()
        messageRef.setValue([
            "user": uuid,
            "text": message,
            "timestamp": timestamp
        ])
        currentConversationRef.setValue([
            "lastMessage": message,
            "timestamp": timestamp,
            "members": [
                uuid: true,
                recipient: true
            ]
        ])
        return Message(id: messageRef.key ?? "", text: message, uuid: uuid, date: date, sending: true)
    }

    func getMessages(success: @escaping (Message, Bool) -> Void) {
//        currentChatRef.queryLimited(toLast: 10).observe(.childAdded, with: { snapshot in
//        currentChatRef.queryLimited(toLast: 10).observe(.value, with: { snapshot in
        currentChatRef.observe(.value, with: { snapshot in
            for (index, child) in snapshot.children.enumerated() {
//                print(child)
                let child = child as! DataSnapshot
                let message = child.value as! [String: Any]
                success(Message(
                        id: child.key,
                        text: message["text"] as! String,
                        uuid: message["user"] as! String,
                        date: Date(timeIntervalSince1970: message["timestamp"] as! Double),
                        sending: false), index == snapshot.childrenCount - 1)
            }
        })
    }

    func getConversations(added: @escaping (Conversation) -> Void, changed: @escaping (Conversation) -> Void) {
        let query = conversationRef.queryOrdered(byChild: "members/\(uuid())").queryEqual(toValue: true)
        query.observe(.childAdded, with: { snapshot in
            MessagesClient.shared.conversation(fromSnapshot: snapshot, callback: added)
        })
        query.observe(.childChanged, with: { snapshot in
            MessagesClient.shared.conversation(fromSnapshot: snapshot, callback: changed)
        })
    }

    func conversation(fromSnapshot snapshot: DataSnapshot, callback: @escaping (Conversation) -> Void) {
        let value = snapshot.value as! [String: Any]
        let members = value["members"] as! [String: Bool]
        for (key, _) in members {
            if (key != self.uuid()) {
                UserClient.shared.get(uuid: key, success: { user in
                    let date = Date(timeIntervalSince1970: value["timestamp"] as! Double)
                    callback(Conversation(
                            user: UserClient.user(fromJson: user),
                            previewText: value["lastMessage"] as! String,
                            date: date.timeAgo,
                            completeDate: date))
                }, failure: { error in })
                continue
            }
        }
    }
}
