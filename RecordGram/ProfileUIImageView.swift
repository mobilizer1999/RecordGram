//
//  ProfileUIImageView.swift
//  RecordGram
//
//  Created by Nicolas Gonzalez on 11/12/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import Foundation
import Kingfisher

class ProfileUIImageView: RoundImageView {
    let placeholder = UIImage(named: "profile_placeholder")

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        fetch()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    func fetch(for uuid: String = UserClient.shared.uuid(), completion: (() -> Void)? = nil) {
        if let profilePicture = UserClient.shared.profilePicture, uuid == UserClient.shared.uuid() {
            self.image = profilePicture
        } else {
            self.image = placeholder
            UserClient.shared.get("profile_picture", for: uuid) { profilePicture in
                self.kf.setImage(with: URL(string: profilePicture), placeholder: self.placeholder)
                if let completion = completion {
                    completion()
                }
            }
        }
    }
}
