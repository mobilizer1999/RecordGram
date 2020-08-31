//
//  Fonts.swift
//  Mauro Taroco
//
//  Created by Mauro Taroco on 11/11/17.
//

import UIKit

private struct Font {
    static let productSansRegular = "ProductSans-Regular"
    static let helveticaNeue = "HelveticaNeue"
}

extension UIFont {

    static let productSansRegularOfSize80 = UIFont(name: Font.productSansRegular, size: 80)
    static let helveticaNeueOfSize15 = UIFont(name: Font.helveticaNeue, size: 15)
    static let helveticaNeueOfSize14 = UIFont(name: Font.helveticaNeue, size: 14)
    static let helveticaNeueOfSize12 = UIFont(name: Font.helveticaNeue, size: 12)
    static let helveticaNeueOfSize11 = UIFont(name: Font.helveticaNeue, size: 11)
    static let helveticaNeueOfSize09 = UIFont(name: Font.helveticaNeue, size: 9)
}
