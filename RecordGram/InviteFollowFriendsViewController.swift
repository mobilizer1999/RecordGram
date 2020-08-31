//
//  InviteFollowFriendsViewController.swift
//  RecordGram
//
//  Created by Mauro Taroco on 6/12/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import SwiftyJSON

class InviteFollowFriendsViewController: UIViewController, ErrorHandler {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var inviteFollowSegment: UISegmentedControl!
    @IBOutlet weak var inviteButton: UIBarButtonItem!

    var friendsType: UserFriendType = .phoneContact
    var peopleToInvite: [UserFriend] = []
    var peopleToFollow: [UserFriend] = []
    var peopleList: [UserFriend] {
        if selectedActionType == .invite {
            return peopleToInvite
        } else {
            return peopleToFollow
        }
    }
    var friendsSelectedForInvitationArray: [String] = [] {
        didSet {
            inviteButton.isEnabled = selectedActionType == .invite && friendsSelectedForInvitationArray.count > 0
        }
    }
    var friendsDataSource: [UserFriend] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    var filterString = "" {
        didSet {
            setUpDataSource()
        }
    }
    var selectedActionType: UserFriendActionType {
        if inviteFollowSegment.selectedSegmentIndex == 0 {
            return .invite
        } else {
            return .follow
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        searchBar.delegate = self

        setUpDataSource()
    }

    func setUpDataSource() {
        if filterString == "" {
            friendsDataSource = peopleList
        } else {
            friendsDataSource = peopleList.filter {
                $0.displayName().lowercased().contains(filterString.lowercased())
            }
        }
    }

    @IBAction func changeSegment(_ sender: Any) {
        setUpDataSource()
    }

    @IBAction func didTapInviteButton() {
        let strData = friendsSelectedForInvitationArray.joined(separator: ",")

        InviteClient.shared.sendInvite(parameters: ["emails": strData], success: { status in
            if status {
                self.view.makeToast(NSLocalizedString("Invitation Sent", comment: "Find and Follow"), duration: 3, position: .center)
            }
            self.dismiss(animated: true)
        }) { error in
            self.presentErrorDialog(error: error)
        }
    }

    @IBAction func didTapCloseButton() {
        self.dismiss(animated: true)
    }
}

extension InviteFollowFriendsViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friendsDataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FriendTableViewCell") as? FriendTableViewCell else {
            return UITableViewCell()
        }
        cell.delegate = self
        cell.setupCell(withFriend: friendsDataSource[indexPath.row], actionType: selectedActionType)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! FriendTableViewCell
        let friend = friendsDataSource[indexPath.row]
        if selectedActionType == .follow {
            if let uuid = friend.uuid {
                if let amFollowing = friend.following {
                    if amFollowing {
                        UserClient.shared.unFollow(uuid: uuid, success: {
                            self.friendsDataSource[indexPath.row].following = false
                            cell.followButton.isSelected = true
                        }, failure: { error in })
                    } else {
                        UserClient.shared.follow(uuid: uuid, success: {
                            self.friendsDataSource[indexPath.row].following = true
                            cell.followButton.isSelected = false
                        }, failure: { error in })
                    }
                }
            }
        } else {
            let friendIdentifier = friend.identifierForInvitation(userFriendsType: friendsType)
            if let friendIndex = friendsSelectedForInvitationArray.index(of: friendIdentifier) {
                friendsSelectedForInvitationArray.remove(at: friendIndex)
                cell.addToInviteButton.isSelected = false
            } else {
                friendsSelectedForInvitationArray.append(friendIdentifier)
                cell.addToInviteButton.isSelected = true
            }
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
}

extension InviteFollowFriendsViewController: UISearchBarDelegate {

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterString = searchText
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        filterString = searchBar.text!
    }
}

extension InviteFollowFriendsViewController: FriendTableViewCellDelegate {

    func isFriendSelectedForInvitation(_ friend: UserFriend) -> Bool {
        return friendsSelectedForInvitationArray.index(of: friend.identifierForInvitation(userFriendsType: friendsType)) != nil
    }
}
