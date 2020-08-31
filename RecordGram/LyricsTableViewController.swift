//
//  LyricsTableViewController.swift
//  RecordGram
//
//  Created by Hugo Prione on 05/12/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit

protocol LyricsTableViewControllerDelegate {
    func didSelectLyric(viewController: LyricsTableViewController, lyric: Lyric)
}

class LyricsTableViewController: UIViewController, ErrorHandler {
    var delegate: LyricsTableViewControllerDelegate?
    
    @IBOutlet var tableView: UITableView!
    var refreshControl: UIRefreshControl!
    
    private var lyrics: [Lyric] = [] {
        didSet {
            self.tableView.reloadData()
            if lyrics.count > 0 {
                //TODO remove empty state view
            }
            else {
                showEmptyStateView(title: NSLocalizedString("No lyrics are available!", comment: "Lyrics"), description: NSLocalizedString("You haven't saved any lyrics yet.", comment: "Lyrics"))
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("My Lyrics", comment: "Lyrics")
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.tableFooterView = UIView()
        
        refreshControl = UIRefreshControl()
        refreshControl.tintColor = .themeColor
        refreshControl.addTarget(self, action: #selector(refresh), for: UIControlEvents.valueChanged)
        tableView.addSubview(refreshControl) // not required when using UITableViewController
        
        setupNavigationBar()
        
        tabBarController?.tabBar.isHidden = true
        tabBarController?.tabBar.isTranslucent = true

        // Uncomment the following line to preserve selection between presentations
        //self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "Search Icon"), style: .plain, target: self, action: #selector(LyricsTableViewController.onSearchButton))
    }
    
    @objc func refresh(sender:AnyObject) {
        getLyrics()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getLyrics()
    }
    
    func getLyrics(){
        //TODO add loading view
        LyricsClient.shared.all(page: 0, success: { (lyrics) in
            self.refreshControl.endRefreshing()
            self.lyrics = lyrics ?? []
        }, failure: { error in
            self.refreshControl.endRefreshing()
            self.presentErrorDialog(error: error)
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func showEmptyStateView(title: String, description: String){
        let emptyStateView = EmptyStateView()
        self.view.addSubview(emptyStateView)
        emptyStateView.constraintsEqualToView(view: self.tableView)
        
        emptyStateView.emptyStateTitle = title
        emptyStateView.emptyStateDescription = description
        emptyStateView.titleFont = .helveticaNeueOfSize14
        emptyStateView.descriptionFont = .helveticaNeueOfSize11
        emptyStateView.emptyStateBackgroundColor = UIColor.init(hex: "EFEEF1")
    }
}

extension LyricsTableViewController: UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Table view data source
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lyrics.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as? LyricTableViewCell else {
            fatalError()
        }
        
        var lyric = lyrics[indexPath.row]
        
        cell.lblTitle.text = lyric.title
        cell.onTapEditButton = {
            let alertController = UIAlertController(title: NSLocalizedString("Name Your Lyrics", comment: "Lyrics"), message: nil, preferredStyle: .alert)
            alertController.addTextField(configurationHandler: { textField in
                textField.placeholder = NSLocalizedString("Name Your Lyrics", comment: "Lyrics")
                textField.text = lyric.title
            })
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Dialog action"), style: .default, handler: { action in
                lyric.title = alertController.textFields?.first?.text
                
                LyricsClient.shared.update(lyric: lyric, success: { lyric in
                    self.lyrics[indexPath.row] = lyric
                    self.tableView.reloadRows(at: [indexPath], with: .fade)
                }, failure: { error in
                    self.presentErrorDialog(error: error)
                })
            }))
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Dialog action"), style: .cancel, handler: nil))
            
            self.present(alertController, animated: true, completion: nil)
        }
        cell.onTapShareButton = {
            let message = NSLocalizedString("Lyrics By Cre8tor App", comment: "Lyrics")
            let title = lyric.title ?? ""
            let body = lyric.body ?? ""
            
            let activityController = UIActivityViewController(activityItems: [message, title, body], applicationActivities: nil)
            activityController.popoverPresentationController?.sourceView = self.view
            activityController.popoverPresentationController?.sourceRect = self.view.frame
            
            self.present(activityController, animated: true, completion: nil)
        }
        cell.onTapDeleteButton = {
            LyricsClient.shared.delete(uuid: lyric.uuid ?? "", success: {
                //self.tableView.deleteRows(at: [indexPath], with: .left)
                self.lyrics.remove(at: indexPath.row)
                self.view.makeToast(NSLocalizedString("Lyrics deleted", comment: "Lyrics"), duration: 3, position: .center)
            }, failure: { error in
                self.presentErrorDialog(error: error)
            })
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        let lyric = lyrics[indexPath.row]
        
        delegate?.didSelectLyric(viewController: self, lyric: lyric)
    }
    
    // Override to support conditional editing of the table view.
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // Override to support editing the table view.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            let lyric = lyrics[indexPath.row]
            
            LyricsClient.shared.delete(uuid: lyric.uuid ?? "", success: {
                self.lyrics.remove(at: indexPath.row)
                self.view.makeToast(NSLocalizedString("Lyrics deleted", comment: "Lyrics"), duration: 3, position: .center)
                //self.tableView.deleteRows(at: [indexPath], with: .left)
            }, failure: { error in
                self.presentErrorDialog(error: error)
            })
        default: break
        }
    }
}
