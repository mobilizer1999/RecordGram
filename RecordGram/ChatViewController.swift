//
//  ChatViewController.swift
//  RecordGram
//
//  Created by Nicolas Gonzalez on 12/9/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import MessageKit
import MapKit
import Kingfisher

class ChatViewController: MessagesViewController {

    var recipient: User?
    var messages: [Message] = []

    override func loadView() {
        super.loadView()
        if let recipient = recipient {
            if let username = recipient.username {
                self.title = "@\(username)"
            }
            if let uuid = recipient.uuid {
                MessagesClient.shared.setup(uuid: uuid)
            }
        }
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName:"backArrow"), style: .plain, target: self, action: #selector(ChatViewController.onBackButton))

        styleMessageInputBar()

        messageInputBar.delegate = self
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self

        maintainPositionOnKeyboardFrameChanged = true

        MessagesClient.shared.getMessages(success: { message, last in
            DispatchQueue.main.async {
                if let i = self.messages.index(where: { $0.messageId == message.messageId }) {
//                    print("AppDebug - Replaced Message \(message.messageId)")
                    self.messages[i] = message
                } else {
//                    print("AppDebug - Get Message \(message.messageId)")
                    self.messages.append(message)
                    if last {
                        self.messagesCollectionView.reloadData()
                        self.messagesCollectionView.scrollToBottom()
                    }
                }
            }
        })

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
    }

    @objc func onBackButton() {
        navigationController?.popViewController(animated: true)
    }

    func styleMessageInputBar() {
//        messageInputBar = MessageInputBar()
        messageInputBar.isTranslucent = false
        if !UIAccessibilityIsReduceTransparencyEnabled() {
            let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
            blurEffectView.frame = messageInputBar.bounds
            blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            messageInputBar.addSubview(blurEffectView)
            messageInputBar.sendSubview(toBack: blurEffectView)
            messageInputBar.backgroundView.backgroundColor = UIColor(white: 1, alpha: 0.7)
        } else {
            messageInputBar.backgroundView.backgroundColor = .white
        }
        messageInputBar.separatorLine.isHidden = true
        messageInputBar.inputTextView.backgroundColor = UIColor(red: 245 / 255, green: 245 / 255, blue: 245 / 255, alpha: 1)
        messageInputBar.inputTextView.placeholderTextColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        messageInputBar.inputTextView.textContainerInset = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 36)
        messageInputBar.inputTextView.placeholderLabelInsets = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 36)
        messageInputBar.inputTextView.layer.borderColor = UIColor(red: 200 / 255, green: 200 / 255, blue: 200 / 255, alpha: 1).cgColor
        messageInputBar.inputTextView.layer.borderWidth = 1.0
        messageInputBar.inputTextView.layer.cornerRadius = 18.0
        messageInputBar.inputTextView.layer.masksToBounds = true
        messageInputBar.inputTextView.scrollIndicatorInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        messageInputBar.setRightStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([messageInputBar.sendButton], forStack: .right, animated: false)
        messageInputBar.sendButton.imageView?.backgroundColor = UIColor(red: 184 / 255, green: 29 / 255, blue: 98 / 255, alpha: 1)
        messageInputBar.sendButton.contentEdgeInsets = UIEdgeInsets(top: 3, left: 5, bottom: 5, right: 3)
        messageInputBar.sendButton.setSize(CGSize(width: 36, height: 36), animated: false)
        messageInputBar.sendButton.image = UIImage(named: "up_arrow")
        messageInputBar.sendButton.title = nil
        messageInputBar.sendButton.imageView?.layer.cornerRadius = 14
        messageInputBar.sendButton.backgroundColor = .clear
        messageInputBar.sendButton.tintColor = UIColor(red: 69 / 255, green: 193 / 255, blue: 89 / 255, alpha: 1)
        messageInputBar.textViewPadding.right = -38
        let button = InputBarButtonItem()
                .configure {
                    $0.image = UIImage(named: "clip")?.withRenderingMode(.alwaysTemplate)
                    $0.setSize(CGSize(width: 36, height: 36), animated: false)
                }.onSelected {
                    $0.tintColor = UIColor(red: 184 / 255, green: 29 / 255, blue: 98 / 255, alpha: 1)
                }.onDeselected {
                    $0.tintColor = UIColor.lightGray
                }.onTouchUpInside { _ in
                    print("AppDebug - Attachment Tapped")
                }
        button.tintColor = UIColor.lightGray
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
        messageInputBar.padding = UIEdgeInsets(top: 6, left: 4, bottom: 6, right: 12)
//        reloadInputViews()
    }
}

extension ChatViewController: MessageInputBarDelegate {
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
//        print("AppDebug - Add Message")
        self.messages.append(MessagesClient.shared.send(message: text))
        inputBar.inputTextView.text = String()
        self.messagesCollectionView.reloadData()
        messagesCollectionView.scrollToBottom()
    }
}

extension ChatViewController: MessagesDataSource {
    func currentSender() -> Sender {
        return Sender(id: UserClient.shared.uuid(), displayName: UserClient.shared.get("username") ?? "")
    }

    func numberOfMessages(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }

    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }

    func avatar(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> Avatar {
        let image: UIImage?
        if let profile_picture = UserClient.shared.get("profile_picture", for: message.sender.id), profile_picture != "" {
            let imageView = UIImageView()
            imageView.kf.setImage(with: URL(string: profile_picture))
            image = imageView.image
        } else {
            image = UIImage(named: "profile_placeholder")
        }
        return Avatar(image: image)
    }

    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
//        let name = message.sender.displayName
//        return NSAttributedString(string: name, attributes: [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .caption1)])
//        return NSAttributedString(string: "", attributes: [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .caption1)])
        return NSAttributedString(string: "", attributes: nil)
    }

    func cellBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
//        let message = message as! Message
//        let string = message.sending ? "Sending" : message.sentDate.timeAgo
//        print("AppDebug Label for \(message.messageId) will display? \(string)")
//        return NSAttributedString(string: string, attributes: [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .caption2)])
        return NSAttributedString(string: message.sentDate.timeAgo, attributes: [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .caption2)])
    }
}

extension ChatViewController: MessagesDisplayDelegate {

    // MARK: - Text Messages
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .white : .darkText
    }

    func detectorAttributes(for detector: DetectorType, and message: MessageType, at indexPath: IndexPath) -> [NSAttributedStringKey: Any] {
        let color: UIColor = isFromCurrentSender(message: message) ? .white : .darkText
        return [
            NSAttributedStringKey.foregroundColor: color,
            NSAttributedStringKey.underlineStyle: NSUnderlineStyle.styleSingle.rawValue,
            NSAttributedStringKey.underlineColor: color
        ]
    }

    func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
        return [.url, .address, .phoneNumber, .date]
    }

    // MARK: - All Messages

    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? UIColor(red: 184 / 255, green: 29 / 255, blue: 98 / 255, alpha: 1) : UIColor(red: 230 / 255, green: 230 / 255, blue: 230 / 255, alpha: 1)
    }

    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        return .bubbleTail(corner, .curved)
    }

    // MARK: - Location Messages
    func annotationViewForLocation(message: MessageType, at indexPath: IndexPath, in messageCollectionView: MessagesCollectionView) -> MKAnnotationView? {
        let annotationView = MKAnnotationView(annotation: nil, reuseIdentifier: nil)
        let pinImage = #imageLiteral(resourceName:"pin")
        annotationView.image = pinImage
        annotationView.centerOffset = CGPoint(x: 0, y: -pinImage.size.height / 2)
        return annotationView
    }

    func animationBlockForLocation(message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> ((UIImageView) -> Void)? {
        return { view in
            view.layer.transform = CATransform3DMakeScale(0, 0, 0)
            view.alpha = 0.0
            UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: [], animations: {
                view.layer.transform = CATransform3DIdentity
                view.alpha = 1.0
            }, completion: nil)
        }
    }
}

extension ChatViewController: MessagesLayoutDelegate {

    func avatarPosition(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> AvatarPosition {
        return AvatarPosition(horizontal: .natural, vertical: .messageBottom)
    }

    func messagePadding(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIEdgeInsets {
        if isFromCurrentSender(message: message) {
            return UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 4)
        } else {
            return UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 30)
        }
    }

    func cellTopLabelAlignment(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> LabelAlignment {
        if isFromCurrentSender(message: message) {
            return .messageTrailing(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10))
        } else {
            return .messageLeading(UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0))
        }
    }

    func cellBottomLabelAlignment(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> LabelAlignment {
        if isFromCurrentSender(message: message) {
            return .messageTrailing(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8))
        } else {
            return .messageLeading(UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0))
        }
    }

    func footerViewSize(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        return CGSize(width: messagesCollectionView.bounds.width, height: 0)
    }

    // MARK: - Location Messages
    func heightForLocation(message: MessageType, at indexPath: IndexPath, with maxWidth: CGFloat, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 200
    }
}
