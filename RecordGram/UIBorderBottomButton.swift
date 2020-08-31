//
//  UIBorderBottomButton.swift
//  RecordGram
//
//  Created by Nicolas Gonzalez on 1/2/18.
//  Copyright © 2018 Meridian Inc. All rights reserved.
//

import UIKit

class UIBorderBottomButton: UIButton {
    
    var border: UIView!
    let thickness: CGFloat = 1.0
    let selectedThickness: CGFloat = 2.0
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        border = UIView()
        self.addSubview(border)
        updateBorder(isSelected: isSelected)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if isSelected {
            border.frame = CGRect(x: 12, y: frame.size.height - selectedThickness, width: frame.size.width - 24, height: selectedThickness)
        } else {
            border.frame = CGRect(x: 12, y: frame.size.height - selectedThickness, width: frame.size.width - 24, height: thickness)
        }
    }
    
    override var isSelected: Bool {
        willSet {
            updateBorder(isSelected: newValue)
        }
    }
    
    private func updateBorder(isSelected: Bool) {
        if isSelected {
            border.backgroundColor = UIColor.white
        } else {
            border.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.3)
        }
    }
}
