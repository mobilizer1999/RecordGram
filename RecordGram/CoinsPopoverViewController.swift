//
//  CoinsPopoverViewController.swift
//  RecordGram
//
//  Created by Dewayne Perry on 10/8/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.

import UIKit
import StoreKit
import Toast_Swift

class CoinsPopoverViewController: UIViewController, SKProductsRequestDelegate, SKPaymentTransactionObserver {

    @IBOutlet weak var coinCount: UILabel!

    var productIdentifiers: Array<String> = [
        "com.recordgramllc.recordgram.250Coins",
        "com.recordgramllc.recordgram.675Coins",
        "com.recordgramllc.recordgram.1700Coins",
        "com.recordgramllc.recordgram.8000Coins"
    ]
    var products: [Int: SKProduct] = [:]
    var productRequest: SKProductsRequest!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateCoinCount()
    }

    func updateCoinCount(success: (() -> Void)? = nil) {
        UserClient.shared.get("credits") { credits in
            self.coinCount.text = credits
            if let success = success {
                success()
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if SKPaymentQueue.canMakePayments() {
            view.loading(with: NSLocalizedString("Setting Up the Store.", comment: "Coins"))

            productRequest = SKProductsRequest(productIdentifiers: NSSet(array: productIdentifiers) as! Set<String>)
            productRequest.delegate = self
            productRequest.start()

            SKPaymentQueue.default().add(self)
        } else {
            print("❗️ Cannot perform In App Purchases.")
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        productRequest.cancel()
        SKPaymentQueue.default().remove(self)
    }

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        if response.products.count != 0 {
            for product in response.products {
                print("💰", product.localizedTitle)
                if let index = productIdentifiers.index(of: product.productIdentifier) {
                    let insertIndex = productIdentifiers.distance(from: productIdentifiers.startIndex, to: index)
                    products[insertIndex] = product
                }
            }
        } else {
            print("⚠️ There are no products.")
        }
        view.loaded()
    }

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                print("👍 Payment Transaction Purchased")
                SKPaymentQueue.default().finishTransaction(transaction)
                let url = Bundle.main.appStoreReceiptURL
                if let url = url {
                    let receipt = NSData(contentsOf: url)
                    if let receipt = receipt {
                        let receiptString = receipt.base64EncodedString()
//                        print(receiptString)
                        CoinsClient.shared.validatePurchase(with: receiptString, success: {
                            self.refreshUser()
                        }, failure: { error in
                            self.view.loaded()
                            print("❗️", error.localizedDescription)
                        })
                    }
                }

            case .failed:
                print("👎 Payment Transaction Error:", transaction.error.debugDescription);
                SKPaymentQueue.default().finishTransaction(transaction)
                self.view.loaded()
            default:
                print("ℹ️", transaction.transactionState.hashValue)
            }
        }
    }

    func refreshUser() {
        UserClient.shared.invalidateUser()
        self.updateCoinCount() {
            self.view.loaded()
        }
    }

    @IBAction func tap(_ sender: UITapGestureRecognizer) {
        if let tag = sender.view?.tag {
            switch tag {
            case -1:
                // Make sure user is only tapping outside...
                let point = sender.location(in: self.view)
                if let viewTouched = self.view.hitTest(point, with: nil), viewTouched == self.view {
                    dismiss(animated: true, completion: nil)
                }
            case 4:
                print("🔄 Sync Coins")
                self.view.loading(with: NSLocalizedString("Syncing Coins!", comment: "Coins"))
                refreshUser()
            default:
                if let product = products[tag] {
                    self.view.loading(with: NSLocalizedString("Nice Choice!", comment: "Coins"))
                    SKPaymentQueue.default().add(SKPayment(product: product))
                } else {
                    print("⚠️ Option not in map!")
                }
            }
        }
    }
}
