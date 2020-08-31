//
//  ARPersonalContentViewController.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 10/9/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.

import UIKit

class ARPersonalContentViewController: UIViewController {
    
    @IBOutlet weak var personalContainerSegmentedController: UISegmentedControl!
    @IBOutlet weak var personalContentCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func onSegmentedController(_ sender: Any) {
        personalContentCollectionView.reloadData()
    }
    
}

extension ARPersonalContentViewController : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 50
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width: CGFloat = (view.frame.width / 3) - (2 * 2)
        let height: CGFloat = personalContainerSegmentedController.selectedSegmentIndex == 0 ? 230.0 : 285.0

        return CGSize(width: width, height: height)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: personalContainerSegmentedController.selectedSegmentIndex == 0 ? "MyVideoCell" : "MySongCell", for: indexPath)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        if personalContainerSegmentedController.selectedSegmentIndex == 0 {
// show media options view
            print("first segment c selected")
        } else {
            print("second segment c selected")
        }
    }
}

