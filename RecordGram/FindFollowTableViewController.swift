//
//  FindFollowTableViewController.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 10/11/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.

import UIKit

import FBSDKCoreKit
import FBSDKShareKit
import TwitterKit
import Contacts

class FindFollowTableViewController: UITableViewController {

    let tableSection = [
        [FindFollowHeaderType.header],
//        [FindFollowHeaderType.facebook, FindFollowRow.inviteFacebook, FindFollowRow.findFollowFacebook],
//        [FindFollowHeaderType.twitter, FindFollowRow.inviteFollowTwitter],
        [FindFollowHeaderType.phoneContact, FindFollowRow.inviteFollowContact],
//        [FindFollowHeaderType.nearby, FindFollowRow.inviteFollowNearby, FindFollowRow.invisibleToUsers],
        [FindFollowHeaderType.randomInvite, FindFollowRow.inviteRecordGram]]

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("Find and Follow", comment: "Find and Follow")
        self.navigationController?.navigationBar.topItem?.title = ""
        let backButtonImage = UIImage(named: "backArrow")
        self.navigationController?.navigationBar.backIndicatorImage = backButtonImage
        self.navigationController?.navigationBar.backIndicatorTransitionMaskImage = backButtonImage

        tableView.register(UINib(nibName: "FindFollowHeaderTableViewCell", bundle: nil), forCellReuseIdentifier: "findFollowHeaderIdentifier")
        tableView.register(UINib(nibName: "FindFollowTableViewCell", bundle: nil), forCellReuseIdentifier: "findFollowRowIdentifier")
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 140
        tableView.estimatedSectionHeaderHeight = 0
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
        tabBarController?.tabBar.isTranslucent = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.mainTab?.shouldShowTour = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return tableSection.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableSection[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let typeCell = tableSection[indexPath.section][indexPath.row]

        if type(of: typeCell) == FindFollowHeaderType.self {
            let cell = tableView.dequeueReusableCell(withIdentifier: "findFollowHeaderIdentifier", for: indexPath) as! FindFollowHeaderTableViewCell
            cell.setupCell(typeCell: typeCell as! FindFollowHeaderType)
            return cell
        } else if type(of: typeCell) == FindFollowRow.self {
            let cell = tableView.dequeueReusableCell(withIdentifier: "findFollowRowIdentifier", for: indexPath) as! FindFollowTableViewCell
            cell.setupCell(typeCell: typeCell as! FindFollowRow)
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "no cell", for: indexPath)
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let typeCell = tableSection[indexPath.section][indexPath.row]

        if type(of: typeCell) == FindFollowHeaderType.self {
            let type = typeCell as! FindFollowHeaderType
            switch type {
            case .nearby:
                selectNearbyMiles()
            default:
                print("header")
            }
        } else if type(of: typeCell) == FindFollowRow.self {
            let type = typeCell as! FindFollowRow
            switch type {
            case .inviteFacebook:
                inviteFBFriends()
            case .findFollowFacebook:
                findAndFollowFBFriends()
            case .inviteFollowTwitter:
                findAndFollowersTwitter()
            case .inviteFollowContact:
                findAndFollowContactPhone()
            case .inviteFollowNearby:
                inviteNearbyUsers()
            case .invisibleToUsers:
                selectVisibleUser()
            case .inviteRecordGram:
                inviteToJoinRecordGram()
            }
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ""
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return ""
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    override func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath) -> Int {
        return 0
    }
}

//MARK: Facebook users

extension FindFollowTableViewController: FBSDKAppInviteDialogDelegate {

    func inviteFBFriends() {
        let inviteDialog: FBSDKAppInviteDialog = FBSDKAppInviteDialog()
        if (inviteDialog.canShow()) {

            let appLinkUrl = URL(string: "https://fb.me/997619793678767")!
            let previewImageUrl = URL(string: "https://www.recordgram.com/frontend/misc/invitation.png")!

            let inviteContent: FBSDKAppInviteContent = FBSDKAppInviteContent()
            inviteContent.appLinkURL = appLinkUrl
            inviteContent.appInvitePreviewImageURL = previewImageUrl

            inviteDialog.content = inviteContent
            inviteDialog.delegate = self
            inviteDialog.show()
        }
    }

    func appInviteDialog(_ appInviteDialog: FBSDKAppInviteDialog!, didCompleteWithResults results: [AnyHashable: Any]!) {
        let resultObject = NSDictionary(dictionary: results)

        if let didCancel = resultObject.value(forKey: "completionGesture") {
            if (didCancel as AnyObject).caseInsensitiveCompare("Cancel") == .orderedSame {
                print("User Canceled invitation dialog")
            }
        }
    }

    func appInviteDialog(_ appInviteDialog: FBSDKAppInviteDialog!, didFailWithError error: Error!) {
        print("Error tool place in appInviteDialog \(error)")
    }

    func findAndFollowFBFriends() {

    }
}

//MARK: Twitter friends
extension FindFollowTableViewController {
    func findAndFollowersTwitter() {
        TwitterManager.shared.loadFollowers(success: { (response) -> (Void) in
            //TODO: parse response and show users.
        }) { () -> (Void) in
            //TODO: show error and remove loading
        }
    }

    func findAndFollowingTwitter() {
        TwitterManager.shared.loadFollowing(success: { (response) -> (Void) in
            //TODO: parse response and show users.
        }) { () -> (Void) in
            //TODO: show error and remove loading
        }
    }
}

//MARK: Nearby users
extension FindFollowTableViewController {
    func selectNearbyMiles() {
        let alertController = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)

        let miles5Button = UIAlertAction(title: NSLocalizedString("5 Miles", comment: "Find and Follow"), style: .default, handler: { (action) -> Void in
            self.setMiles(miles: "5")
        })

        let miles10Button = UIAlertAction(title: NSLocalizedString("10 Miles", comment: "Find and Follow"), style: .default, handler: { (action) -> Void in
            self.setMiles(miles: "10")
        })

        let miles20Button = UIAlertAction(title: NSLocalizedString("20 Miles", comment: "Find and Follow"), style: .default, handler: { (action) -> Void in
            self.setMiles(miles: "20")
        })

        let miles50Button = UIAlertAction(title: NSLocalizedString("50 Miles", comment: "Find and Follow"), style: .default, handler: { (action) -> Void in
            self.setMiles(miles: "50")
        })

        let cancelButton = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Dialog option"), style: .cancel, handler: nil)

        alertController.addAction(miles5Button)
        alertController.addAction(miles10Button)
        alertController.addAction(miles20Button)
        alertController.addAction(miles50Button)
        alertController.addAction(cancelButton)

        self.present(alertController, animated: true, completion: nil)
    }

    func setMiles(miles: String) {
        UserDefaults.setNearbyMiles(miles: miles)
        self.tableView.reloadData()
    }


    func selectVisibleUser() {
        let messageVisible = NSLocalizedString("Currently you are visible to other nearby users. \n Do you want make yourself invisible in nearby search ?", comment: "Find and Follow")
        let messageInVisible = NSLocalizedString("Currently you are invisible other nearby users. \n Do you want make yourself visible in nearby search ?", comment: "Find and Follow")

        let message = UserDefaults.isVisibleNearby() ? messageVisible : messageInVisible

        self.showAlert(title: NSLocalizedString("Alert!", comment: "Dialog option"), message: message, actionTitles: [NSLocalizedString("No", comment: "Dialog option"), NSLocalizedString("Yes", comment: "Dialog option")], actions: [{ action1 in
            print("no action")
        }, { action2 in
            self.updateNearbySearchFlagOfUser()
        }, nil])
    }

    func updateNearbySearchFlagOfUser() {
        UserClient.shared.enableVisible(visible: !(UserDefaults.isVisibleNearby()), success: { (response) in
            UserDefaults.setObject(value: !(UserDefaults.isVisibleNearby()), key: "visible_in_nearby")
            self.tableView.reloadData()
        }) { (error) in
            //TODO: return error and show alert
        }
    }
}

extension FindFollowTableViewController {
    func findAndFollowContactPhone() {

        var phoneBookContacts = [CNContact]()

        let store = CNContactStore()
        store.requestAccess(for: .contacts, completionHandler: { (granted, error) in
            guard granted else {
                let alert = UIAlertController(title: NSLocalizedString("Oops!", comment: "Dialog title"), message: NSLocalizedString("Please enable access to your contacts", comment: "Dialog message"), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Dialog option"), style: .cancel, handler: nil))
                alert.addAction(UIAlertAction(title: NSLocalizedString("Open Settings", comment: "Dialog option"), style: .default, handler: { (action) in
                    self.openSettings()
                }))
                self.present(alert, animated: true, completion: nil)
                return
            }

            let keysToFetch = [CNContactFormatter.descriptorForRequiredKeys(for: .fullName), CNContactPhoneNumbersKey, CNContactEmailAddressesKey, CNContactImageDataKey] as [Any]
            let request = CNContactFetchRequest(keysToFetch: keysToFetch as! [CNKeyDescriptor])
            request.sortOrder = CNContactSortOrder.givenName
            var cnContacts = [CNContact]()

            do {
                try store.enumerateContacts(with: request, usingBlock: { (contact, cursor) in
                    cnContacts.append(contact)
                })
            } catch let error {
                NSLog("Fetch contact error: \(error)")
            }

//            NSLog(">>>> Contact list:")
//            for contact in cnContacts {
//                let fullName = CNContactFormatter.string(from: contact, style: .fullName) ?? "No Name"
//                NSLog("\(fullName): \(contact.phoneNumbers.description)")
//            }


            ///Remove Duplicate Values
            var tempSet = NSOrderedSet(array: cnContacts)
            phoneBookContacts = tempSet.array as! [CNContact]
            /////Check Follow Unfollow
            if phoneBookContacts != nil && phoneBookContacts.count > 0 {
                //var sortByName = NSSortDescriptor(key: kUserName, ascending: true)
                //var sortDescriptors = [sortByName]
                //phoneBookContacts = phoneBookContacts.sortedArray(using: sortDescriptors)

                DispatchQueue.main.async(execute: {
                    var userFriends = phoneBookContacts.map({ contact in
                        UserFriend(uuid: "", name: contact.givenName, username: "", email: contact.emailAddresses.first?.value as String?, image: contact.imageData, profileImageUrl: "")
                    })

                    userFriends = self.removeDuplicatesUserFriendByEmail(array: userFriends)
                    self.findPeople(friends: userFriends, forType: .phoneContact)
                    //self.goToInviteFollowFriends(withFriends: userFriends, andFriendsType: .phoneContact)
                })
            } else {
                self.view.makeToast(NSLocalizedString("😟\nNo Contact Found", comment: "Find and Follow"), duration: 3, position: .center)
            }

        })
    }

    func removeDuplicates(array: [String]) -> [String] {
        var encountered = Set<String>()
        var result: [String] = []
        for value in array {
            if encountered.contains(value) {
                // Do not add a duplicate element.
            } else {
                // Add value to the set.
                encountered.insert(value)
                // ... Append the value.
                result.append(value)
            }
        }
        return result
    }

    func removeDuplicatesUserFriendByEmail(array: [UserFriend]) -> [UserFriend] {
        var encountered = Set<String>()
        var result: [UserFriend] = []
        for value in array {
            if let email = value.email {
                if encountered.contains(email) {
                    // Do not add a duplicate element.
                } else {
                    // Add value to the set.
                    encountered.insert(email)
                    // ... Append the value.
                    result.append(value)
                }
            }
        }
        return result
    }

    //find-people accepts `emails`, `facebook_ids`, and `twitter_ids` arrays
    func findPeople(friends userFriends: [UserFriend], forType type: UserFriendType) {

        let jsonBody = self.jsonToPost(friends: userFriends, andType: type)
        UserClient.shared.findPeople(parameters: jsonBody, success: { findPeopleResult in
            if let findPeopleResult = findPeopleResult {
                if (type == .facebook) {
                    //TODO: implement
                    //self.populateFBFriends(withData: auxResponse)
                } else if (type == .twitter) {
                    //TODO: implement
                    //self.populateTwitterFollowersFollowings(withData: auxResponse)
                } else if (type == .phoneContact) {
                    //self.goToInviteFollowFriends(withFriends: userFriends, andFriendsType: type)
                    self.goToInviteFollowFriends(withPeopleToInvite: userFriends, peopleToFollow: findPeopleResult, friendsType: type)
                }
            }
        }, failure: { error in

        })
    }


    func jsonToPost(friends: [UserFriend], andType type: UserFriendType) -> [String: String] {
        var tempDataArr: [String] = []
        //var dataForJson: Data? = nil
        //var jsonData: String? = nil
        var dictionaryToBePost: [String: String]? = nil
        if (type == .facebook) {
            //TODO: implement
//            tempDataArr = friends.map {{ $0.id }}
//            dictionaryToBePost = [kSocialType: type, "social_user_ids": tempDataArr]
//            dataForJson = dictionaryToBePost?.jsonData()
//            jsonData = dataForJson?.dataString as? String
        } else if (type == .twitter) {
            //TODO: implement
//            tempDataArr = friends.map {{ $0.id }}
//            dictionaryToBePost = [kSocialType: type, "social_user_ids": tempDataArr]
//            dataForJson = dictionaryToBePost?.jsonData()
//            jsonData = dataForJson?.dataString as? String
        } else if (type == .phoneContact) {

//            tempDataArr = friends.flatMap({ contact in
//                contact.emailAddresses.first?.value
//            }) as [String]

            tempDataArr = friends.flatMap({ usrFriend in
                usrFriend.email
            }) as [String]

            //Remove duplicates
            tempDataArr = (Array(NSOrderedSet(array: tempDataArr)) as? [String]) ?? []
            //tempDataArr = removeDuplicates(array: tempDataArr)

            let strData = tempDataArr.joined(separator: ",")

            dictionaryToBePost = ["emails": strData,
                                  "google_ids": "",
                                  "twitter_ids": "",
                                  "facebook_ids": ""]

//            dataForJson = dictionaryToBePost.jsonData()
//            jsonData = dataForJson.dataString
        }

        //return jsonData ?? ""
        return dictionaryToBePost ?? ["": ""]
    }

}


extension FindFollowTableViewController {
    //Maybe the best is move this methods to a controller or InviteFollowFriendsViewController
    //Also we can control the paginations of this.
    func inviteNearbyUsers() {
        LocationTracker.shared.getCurrentLocation() { _ in
            //Loading the first
            if LocationTracker.shared.existCoordenates() {
                self.getNearbyUsers(page: "1")
            } else {
                let alertController = UIAlertController(title: NSLocalizedString("Oops!", comment: "Dialog title"), message: NSLocalizedString("😟\nWe doesn't have your updated Coordinates.\nEither restart the app or check in Settings whether the app has permission to use your location!", comment: "Dialog message"), preferredStyle: .alert)

                let openSettingsButton = UIAlertAction(title: NSLocalizedString("Open Settings", comment: "Dialog option"), style: .default, handler: { (action) -> Void in
                    self.openSettings()
                })
                let cancelButton = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Dialog option"), style: .cancel, handler: nil)

                alertController.addAction(openSettingsButton)
                alertController.addAction(cancelButton)

                self.present(alertController, animated: true, completion: nil)

            }
        }
    }

    func getNearbyUsers(page: String) {
        UserClient.shared.getNearbyUser(parameters: parametersNearbyUsers(page: page), success: { (response) in
            print(response)
            if let success = response[kStatus].bool, success {
                //TODO: show InviteFollowFriendsViewController/
                //Parsing data.
                if let data = response[kData].dictionaryObject {
                    //populateNearbyUserWithData(withData: auxResponse)
                }

            } else if let message = response[kData].string, !message.isEmpty {
                if page.elementsEqual("1") {
                    self.view.makeToast(NSLocalizedString("😟 \nNo users found in selected radius!", comment: "Find and Follow"), duration: 3, position: .center)
                } else {
                    self.view.makeToast(message, duration: 3, position: .center)
                }
                //pageIndexForNearbyUsers--
            } else {
                self.view.makeToast(NSLocalizedString("Unknow error...", comment: "Find and Follow"), duration: 3, position: .center)
                //pageIndexForNearbyUsers--
            }
        }) { (error) in
            //TODO:
            print(error.localizedDescription)
            //pageIndexForNearbyUsers--
        }
    }

    func parametersNearbyUsers(page: String) -> [String: Any] {
        var parameters = [String: Any]()

        parameters[kPageIndex] = page
        parameters[kLimit] = "20"
        parameters[kSearchText] = ""

        parameters[kLatitude] = LocationTracker.shared.latitude
        parameters[kLongitude] = LocationTracker.shared.longitude

        parameters[kDistance] = "\(Float(UserDefaults.nearbyMiles())! * 1609.34)"

        return parameters
    }
}

extension FindFollowTableViewController {
    func inviteToJoinRecordGram() {
        let invitationMessage = NSLocalizedString("Try this amazing app on the App Store!", comment: "Share")
        let invitationURL = "https://appsto.re/in/37midb.i"
        let items = [invitationMessage, invitationURL] as [Any]

        let shareActivityController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        shareActivityController.popoverPresentationController?.sourceView = self.view
        shareActivityController.completionWithItemsHandler = { activity, success, items, error in
            print("show success message")
        }
        self.present(shareActivityController, animated: true, completion: nil)
    }
}

extension FindFollowTableViewController {
    func openSettings() {
        guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
            return
        }

        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                print("Settings opened: \(success)") // Prints true
            })
        }
    }

    /*
 
     `POST /invite` accepts `emails` as an array of strings
     `POST /users/follow` accepts `emails` as an array of strings
     
     invites will ignore users already on the system, while follow will ignore users it can’t find, so you can call both endpoints with the same data
     
     */
    func goToInviteFollowFriends(withPeopleToInvite peopleToInvite: [UserFriend], peopleToFollow: [UserFriend], friendsType: UserFriendType) {
        let storyboard = UIStoryboard(name: "Menu", bundle: Bundle.main)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "InvitableOrFollowableFriendsVC") as? InviteFollowFriendsViewController else {
            return
        }

        viewController.peopleToInvite = peopleToInvite
        viewController.peopleToFollow = peopleToFollow
        viewController.friendsType = friendsType

        self.present(viewController, animated: true)
    }
}
