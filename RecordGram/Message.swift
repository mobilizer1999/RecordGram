//
//  Message.swift
//  RecordGram
//
//  Created by Nicolas Gonzalez on 12/30/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import MessageKit

struct Message: MessageType {
    
    var sender: Sender
    var messageId: String
    var sentDate: Date
    var data: MessageData
    var sending: Bool
    
    init(id: String, text: String, uuid: String, date: Date, sending: Bool) {
        self.data = .text(text)
        self.sender = Sender(id: uuid, displayName: UserClient.shared.get("username", for: uuid) ?? "")
        self.messageId = id
        self.sentDate = date
        self.sending = sending
    }
}
