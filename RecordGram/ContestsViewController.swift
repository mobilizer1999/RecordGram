//
//  ContestsViewController.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 10/11/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.

import UIKit

class ContestsViewController: UIViewController {

    @IBOutlet weak var contestHeaderView: UIImageView!
    @IBOutlet var tableView: UITableView!

    let contestCellId = "contestCellId"
    var contestDetailsVC = ContestDetailsViewController()
    let emptyStateView = EmptyStateView()
    var refreshControl: UIRefreshControl!
    
    private var contests: [Contest] = [] {
        didSet {
            self.tableView.reloadData()
            if contests.count > 0 {
                self.removeEmptyStateView()
            }
            else {
                showEmptyStateView(title: NSLocalizedString("No active contests are available!", comment: "Contests"), description: "")
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        self.title = NSLocalizedString("CONTESTS", comment: "Contests")
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
        tabBarController?.tabBar.isTranslucent = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.tableFooterView = UIView()
        contestHeaderView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ContestsViewController.didTapContestHeaderView))
        tapGesture.numberOfTapsRequired = 1
        contestHeaderView.addGestureRecognizer(tapGesture)
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName:"backArrow"), style: .plain, target: self, action: #selector(ContestsViewController.onBackButton))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "Search Icon"), style: .plain, target: self, action: #selector(ContestsViewController.onSearchButton))
        
        refreshControl = UIRefreshControl()
        refreshControl.tintColor = .themeColor
        refreshControl.addTarget(self, action: #selector(refresh), for: UIControlEvents.valueChanged)
        tableView.addSubview(refreshControl)

        tableView.estimatedRowHeight = 40
        tableView.rowHeight = UITableViewAutomaticDimension
        getContests()
    }

    @objc func onBackButton() {
        navigationController?.popViewController(animated: true)
    }

    @objc func refresh(sender:AnyObject) {
        getContests()
    }

    @objc func didTapContestHeaderView() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "ContestDetailsViewController") as! ContestDetailsViewController
        navigationController?.pushViewController(vc, animated: true)
    }

    func getContests() {
        ContestsClient.shared.all(success: { (contests) in
            self.refreshControl.endRefreshing()
            self.contests = contests ?? []
            
        }, failure: { error in
            self.refreshControl.endRefreshing()
            //self.presentErrorDialog(error: error)
        })
    }
    
    func showEmptyStateView(title: String, description: String){
        self.view.addSubview(emptyStateView)
        emptyStateView.constraintsEqualToView(view: self.tableView)
        
        emptyStateView.emptyStateTitle = title
        emptyStateView.emptyStateDescription = description
        emptyStateView.titleFont = .helveticaNeueOfSize14
        emptyStateView.descriptionFont = .helveticaNeueOfSize11
        emptyStateView.emptyStateBackgroundColor = UIColor.init(hex: "EFEEF1")
    }
    
    func removeEmptyStateView() {
        emptyStateView.removeFromSuperview()
    }
}

extension ContestsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: contestCellId, for: indexPath) as? ContestTableViewCell else {
            fatalError()
        }
        
        let contest = contests[indexPath.row]
        cell.setupCell(withContest: contest)
        cell.tapVideoView = { contest in
            self.tapVideoAction(contest: contest)
        }
        
        cell.tapTransparantView = { contest in
            self.tapTransparent(contest: contest)
        }

        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contests.count
    }
}

extension ContestsViewController {

    func tapVideoAction(contest: Contest) {
        if contest.type == .song {
            showVideoPlayer(contest: contest)
        } else if contest.type == .video {
            showImagePlayer(contest: contest)
        }
    }
    
    func tapTransparent(contest: Contest) {
        let storyBoard = UIStoryboard(name: "Contests", bundle: nil)
        let contestDetailsViewController = storyBoard.instantiateViewController(withIdentifier: "ContestDetailsViewController") as! ContestDetailsViewController
        contestDetailsViewController.contest = contest
        self.navigationController?.pushViewController(contestDetailsViewController, animated: true)
    }
}

extension ContestsViewController {
    func showVideoPlayer(contest: Contest) {
        //TODO
    }
    
    func showImagePlayer(contest: Contest) {
        //TODO
    }

}
