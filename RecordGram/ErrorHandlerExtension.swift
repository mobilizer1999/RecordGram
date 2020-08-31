//
//  ErrorHandlerExtension.swift
//  RecordGram
//
//  Created by Hugo Prione on 6/24/16.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import Crashlytics

protocol ErrorHandler {
    func presentErrorDialog(error: Error)
    func presentErrorDialog(string: String)
    func logError(error: Error)
    func logError(string: String)
}

extension ErrorHandler where Self: UIViewController {
    func presentErrorDialog(error: Error) {
        presentErrorDialog(string: error.localizedDescription)
    }
    
    func logError(error: Error) {
        logError(string: error.localizedDescription)

        Crashlytics.sharedInstance().recordError(error)
    }
    
    func presentErrorDialog(string: String) {
        logError(string: string)
        
        let viewController = UIAlertController(title: NSLocalizedString("Error", comment: "Error title"), message: string, preferredStyle: .alert)
        viewController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Error confirmation"), style: .default, handler: nil))
        
        present(viewController, animated: true, completion: nil)
    }
    
    func logError(string: String) {
        print("Error \(string)")
    }
}
