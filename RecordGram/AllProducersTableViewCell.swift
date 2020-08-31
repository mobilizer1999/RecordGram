//
//  AllProducersTableViewCell.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/7/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit

class AllProducersTableViewCell: UITableViewCell {
    
    let producerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 32.5
        return imageView
    }()
    
    let producerNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "BebasNeueRG-Regular", size: 17)
        label.textColor = UIColor.init(hex: "0x240528")
        return label
    }()
    
    let followersCountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "BebasNeueRG-Regular", size: 17)
        label.textColor = UIColor.init(hex: "0x240528")
        return label
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
        addSubview(producerImageView)
        addSubview(producerNameLabel)
        addSubview(followersCountLabel)

        producerImageView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: nil, paddingTop: 15, paddingLeft: 12, paddingBottom: 15, paddingRight: 0, width: 65, height: 65)
        producerNameLabel.anchor(top: topAnchor, left: producerImageView.rightAnchor, bottom: nil, right: nil, paddingTop: 15, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        followersCountLabel.anchor(top: producerNameLabel.bottomAnchor, left: producerImageView.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 5, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
