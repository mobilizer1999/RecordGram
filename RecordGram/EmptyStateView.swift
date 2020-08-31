//
//  EmptyStateView.swift
//  RecordGram
//
//  Created by Mauro Taroco on 12/29/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import Foundation
import UIKit
let kEmptyStateViewTag = 10461

class EmptyStateView: CustomView {

    // MARK: - Properties
    var emptyStateTitle: String = "" {
        didSet {
            self.titleLabel.text = emptyStateTitle
        }
    }
    var emptyStateDescription: String = "" {
        didSet {
            self.descriptionLabel.text = emptyStateDescription
        }
    }
    
    var titleFont: UIFont? {
        didSet {
            self.titleLabel.font = titleFont
        }
    }
    var descriptionFont: UIFont? {
        didSet {
            self.descriptionLabel.font = descriptionFont
        }
    }
    
    var textColor: UIColor?{
        didSet {
            self.titleLabel.textColor = textColor
            self.descriptionLabel.textColor = textColor
        }
    }
    
    var emojiSize: CGFloat = 50.0 {
        didSet {
            emojiImageSizeConstraint.constant = emojiSize
            emojiImageView.layer.cornerRadius = emojiSize / 2
        }
    }
    
    var emptyStateBackgroundColor: UIColor = .clear {
        didSet {
            backgroundView.backgroundColor = emptyStateBackgroundColor
        }
    }
    
    // MARK: - Outlets
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var parentContainer: UIView!
    @IBOutlet weak var emojiImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var emojiImageSizeConstraint: NSLayoutConstraint!
    
    
    
    
    override func setupView() {
        self.tag = kEmptyStateViewTag
        setupDefaultValues()
    }
    
    func setupDefaultValues() {
        emojiImageView.image = UIImage(named: "unhappyFaceIcon")
        titleFont = .helveticaNeueOfSize15
        descriptionFont = .helveticaNeueOfSize12
        textColor = UIColor.init(hex: "7F7F7F")
    }
    
    func hide() {
        UIView.animate(withDuration: 0.2, animations: {
            self.alpha = 0
        }) { [weak self] finished in
            self?.removeFromSuperview()
        }
    }
    
}
