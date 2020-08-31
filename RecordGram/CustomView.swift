//
//  CustomView.swift
//  RecordGram
//
//  Created by Mauro Taroco on 12/29/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import Foundation
import UIKit

class CustomView: UIView {
    
    // MARK: - Initializers
    
    override init(frame: CGRect) { //For using CustomView in code
        super.init(frame: CGRect.zero)
        loadViewFromNib()
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) { //For using CustomView in IB
        super.init(coder: aDecoder)
        loadViewFromNib()
        setupView()
    }
    
    // MARK: CustomView methods
    
    func setupView() {}
    
}
