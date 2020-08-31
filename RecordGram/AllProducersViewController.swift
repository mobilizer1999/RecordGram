//
//  AllProducersViewController.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/6/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import PagedArray

class AllProducersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, ErrorHandler {

    @IBOutlet weak var allProducersTableView: UITableView!

    let placeholder = UIImage(named: "profile_placeholder")

    var producers: [String: [Producer]] = [:]
    var sections: [String] = []

    override func loadView() {
        super.loadView()

        ProducersClient.shared.all(success: { producers in
            if let producers = producers {
                for producer in producers {
                    let letters = CharacterSet.letters
                    let name = producer.username?.count != 0 ? producer.username : producer.name
                    if let name = name {
                        let key = letters.contains(name.unicodeScalars.first ?? "#") ? String(describing: name.first ?? "#").uppercased() : "#"
                        if var group = self.producers[key] {
                            group.append(producer)
                            self.producers[key] = group
                        } else {
                            self.producers[key] = [producer]
                        }
                    }
                }
                for (key, group) in self.producers {
                    self.producers[key] = group.sorted(by: {
                        if let name0 = ($0.username?.count != 0 ? $0.username : $0.name), let name1 = ($1.username?.count != 0 ? $1.username : $1.name) {
                            return name0.uppercased() < name1.uppercased()
                        }
                        return false
                    })
                }
                self.sections = [String](self.producers.keys)
                self.sections = self.sections.sorted()
                self.allProducersTableView.reloadData()
            }
        }, failure: { error in
            self.presentErrorDialog(error: error)
        })
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("ALL PRODUCERS (A-Z)", comment: "All Producers")
        self.tabBarController?.tabBar.isTranslucent = true
        self.tabBarController?.tabBar.isHidden = true

        self.navigationController?.navigationBar.topItem?.title = ""
        let backButtonImage = UIImage(named: "backArrow")
        self.navigationController?.navigationBar.backIndicatorImage = backButtonImage
        self.navigationController?.navigationBar.backIndicatorTransitionMaskImage = backButtonImage


        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "Search Icon"), style: .plain, target: self, action: #selector(AllProducersViewController.onSearchButton))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let group = producers[sections[section]] {
            return group.count
        }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "producersCell", for: indexPath) as! AllProducersTableViewCell

        if let group = producers[sections[indexPath.section]] {
            let producer = group[indexPath.row]
            if let username = producer.username, username.count != 0 {
                cell.producerNameLabel.text = "@\(username)"
            } else if let name = producer.name {
                cell.producerNameLabel.text = name + " "
            } else {
                cell.producerNameLabel.text = " "
            }
            cell.producerImageView.kf.setImage(with: producer.profilePicture, placeholder: placeholder)
            if let followersCount = producer.followersCount {
                cell.followersCountLabel.text = NSLocalizedString(String(format: "Followers: %d", followersCount), comment: "Producer followers")
            } else {
                cell.followersCountLabel.text = NSLocalizedString("Followers: 0", comment: "Producer followers")
            }
        } else {
            cell.producerNameLabel.text = " "
            cell.producerImageView.image = placeholder
            cell.followersCountLabel.text = NSLocalizedString("Followers: 0", comment: "Producer followers")
        }

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 95
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let group = producers[sections[indexPath.section]] {
            let producer = group[indexPath.row]
            if let uuid = producer.uuid {
                goToProducerProfile(with: uuid)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.font = UIFont(name: "BebasNeueRG-Regular", size: 20)
        header.textLabel?.textColor = UIColor(hex: "0x240528")
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section]
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return sections
    }
}
