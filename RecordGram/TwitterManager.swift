//
//  TwitterManager.swift
//  RecordGram
//
//  Created by Mauro Taroco on 5/12/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import TwitterKit
import SwiftyJSON

class TwitterManager: NSObject {
    static let shared = TwitterManager()

    //This values is loaded when request to twiiter finish and the service checkFollowUnfollowFriends finish.
    var twitterFollowersToInvite = [String: Any]()
    var twitterFollowersToFollow = [String: Any]()
    var twitterFollowingsToInvite = [String: Any]()
    var twitterFollowingsToFollow = [String: Any]()

    var twitterFollowersPageCursor: String = "0"
    var twitterFollowingsPageCursor: String = "0"

    var twitterID: String = ""
    
    enum TwitterPage {
        case firstFollower(twitterId: String)
        case nextFollower(twitterId: String, cursor: String)
        case firstFollowing(twitterId: String)
        case nextFollowing(twitterId: String, cursor: String)
        
        var twitterParameter: [String: Any] {
            switch self {
            case .firstFollower(let twitterId), .firstFollowing(let twitterId):
                return [
                    kUserIdParam: twitterId,
                    kCountParam: kPageLimitTwitter
                ]
            case .nextFollower(let twitterId, let cursor), .nextFollowing(let twitterId, let cursor):
                return [
                    kUserIdParam: twitterId,
                    kCountParam: kPageLimitTwitter,
                    kCursorParam: cursor
                ]
            }
        }
    }
    
    override init() {
        super.init()
        self.startTwitter()
    }

    func startTwitter() {
        TWTRTwitter.sharedInstance().start(withConsumerKey: "yJB0CxJ0c9xiTN4Oqy9yIrEo4", consumerSecret: "tuGs8LeXnXhAj1fye5PHnSuztgrYofGPEx1Pa9oISVXgtYwiQO")
    }

    func loadFollowing(success: @escaping ([JSON]) -> (Void), failure: @escaping () -> (Void)) {
        if twitterID.isEmpty {
            TWTRTwitter.sharedInstance().logIn {(session, error) in
                if let sessionValue = session {
                    print("logged in user with id \(sessionValue.userID)")
                    self.twitterID = sessionValue.userID
                    self.getFollowingsUsers(success: success, failure: failure)
                } else {
                    failure()
                    return
                }
            }
        } else {
            self.getFollowingsUsers(success: success, failure: failure)
        }
    }
    
    func loadFollowers(success: @escaping ([JSON]) -> (Void), failure: @escaping () -> (Void)) {
        if twitterID.isEmpty {
            TWTRTwitter.sharedInstance().logIn {(session, error) in
                if let sessionValue = session {
                    print("logged in user with id \(sessionValue.userID)")
                    self.twitterID = sessionValue.userID
                    self.getFollowingsUsers(success: success, failure: failure)
                } else {
                    failure()
                    return
                }
            }
        } else {
            self.getFollowersUsers(success: success, failure: failure)
        }
    }

    func getFollowingsUsers(success: @escaping ([JSON]) -> (Void), failure: @escaping () -> (Void)) {
        var twitterType: TwitterPage
        
        if twitterFollowingsPageCursor.elementsEqual("0") {
            twitterType = TwitterPage.firstFollowing(twitterId: twitterID)
        } else {
            twitterType = TwitterPage.nextFollowing(twitterId: twitterID, cursor: twitterFollowingsPageCursor)
        }
        
        let client = TWTRAPIClient()
        let statusesShowEndpoint = "https://api.twitter.com/1.1/friends/list.json"
        var clientError : NSError?
        
        let request = client.urlRequest(withMethod: "GET", urlString: statusesShowEndpoint, parameters: twitterType.twitterParameter, error: &clientError)
        
        client.sendTwitterRequest(request) { (response, data, connectionError) -> Void in
            if connectionError != nil {
                print("Error: \(connectionError)")
                failure()
                return
            }
            
            if let responseValue = response {
                let json = JSON(responseValue)
                print("json: \(json)")
                
                if let users = json[kUsers].array {
                    if let cursor = json[kNextCursor].string {
                        self.twitterFollowingsPageCursor = cursor
                    }
                    success(users)
                } else {
                    failure()
                }
            } else {
                failure()
                return
            }
        }
    }
    
    func getFollowersUsers(success: @escaping ([JSON]) -> (Void), failure: @escaping () -> (Void)) {
        var twitterType: TwitterPage
        
        if twitterFollowersPageCursor.elementsEqual("0") {
            twitterType = TwitterPage.firstFollower(twitterId: twitterID)
        } else {
            twitterType = TwitterPage.nextFollower(twitterId: twitterID, cursor: twitterFollowersPageCursor)
        }

        let client = TWTRAPIClient()
        let statusesShowEndpoint = "https://api.twitter.com/1.1/followers/list.json"
        var clientError : NSError?
        
        let request = client.urlRequest(withMethod: "GET", urlString: statusesShowEndpoint, parameters: twitterType.twitterParameter, error: &clientError)
        
        client.sendTwitterRequest(request) { (response, data, connectionError) -> Void in
            if connectionError != nil {
                print("Error: \(connectionError)")
                failure()
                return
            }
            
            if let responseValue = response {
                let json = JSON(responseValue)
                print("json: \(json)")

                if let users = json[kUsers].array {
                    if let cursor = json[kNextCursor].string {
                        self.twitterFollowersPageCursor = cursor
                    }
                    success(users)
                } else {
                    failure()
                }
                
            } else {
                failure()
                return
            }
        }
    }
}
