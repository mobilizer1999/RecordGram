//
//  ConversationsViewController
//  RecordGram
//
//  Created by Nicolas Gonzalez on 12/17/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.

import UIKit

class ConversationsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var messagesTableView: UITableView!

    var conversations: [Conversation] = []

    override func loadView() {
        super.loadView()
        // TODO Detach listeners when view deinits
        MessagesClient.shared.getConversations(added: { conversation in
            self.conversations.append(conversation)
            self.sortAndReloadConversations()
        }, changed: { conversation in
            if let i = self.conversations.index(where: { $0.user.uuid == conversation.user.uuid }) {
                self.conversations[i] = conversation
                self.sortAndReloadConversations()
            }
        })
    }

    func sortAndReloadConversations() {
        self.conversations.sort() { conversation1, conversation2 in
            return conversation1.completeDate > conversation2.completeDate
        }
        self.messagesTableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        messagesTableView.delegate = self
        messagesTableView.dataSource = self
        messagesTableView.rowHeight = 80
        self.title = NSLocalizedString("Messages", comment: "Messages")
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName:"backArrow"), style: .plain, target: self, action: #selector(NotificationsViewController.onBackButton))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = true
        tabBarController?.tabBar.isTranslucent = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }

    @objc func onBackButton() {
        navigationController?.popViewController(animated: true)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "messages", for: indexPath) as! MessagesTableViewCell
        cell.messageProfilePic.kf.setImage(with: conversations[indexPath.row].user.picture, placeholder: UIImage(named: "profile_placeholder"))
        cell.messageName.text = conversations[indexPath.item].user.username
        cell.messagePreviewText.text = conversations[indexPath.item].previewText
        cell.messageDate.text = conversations[indexPath.item].date
        cell.verifiedImageView.isHidden = !(conversations[indexPath.row].user.isVerified ?? false)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "Chat", sender: conversations[indexPath.item].user)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if segue.identifier == "Invite" {
            (segue.destination as! ChatInviteViewController).delegate = self
        }
        if segue.identifier == "Chat" {
            (segue.destination as! ChatViewController).recipient = sender as? User
        }
    }
}
