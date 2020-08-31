//
//  LyricTableViewCell.swift
//  RecordGram
//
//  Created by Hugo Prione on 05/12/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit

class LyricTableViewCell: UITableViewCell {
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var btnDelete: UIButton!
    @IBOutlet weak var btnShare: UIButton!
    @IBOutlet weak var btnEdit: UIButton!
    
    var onTapEditButton: (() -> Void)?
    var onTapShareButton: (() -> Void)?
    var onTapDeleteButton: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    // MARK: - IBActions
    
    @IBAction func didTapEditButton(_ sender: Any) {
        onTapEditButton?()
    }
    
    @IBAction func didTapShareButton(_ sender: Any) {
        onTapShareButton?()
    }
    
    @IBAction func didTapDeleteButton(_ sender: Any) {
        onTapDeleteButton?()
    }
}
