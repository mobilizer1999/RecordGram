//
//  NotificationsViewController.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/27/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.

import UIKit
import PagedArray

class NotificationsViewController: UIViewController, ErrorHandler {

    @IBOutlet weak var tableView: UITableView!

    private var clearAllAnimationInProgress: Bool = false
    private var clearAllBtn: UIButton!

    private lazy var notificationsComponent = NotificationComponent()

    private var topBarHeight: CGFloat = 0.0

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        tabBarController?.tabBar.isHidden = true
        tabBarController?.tabBar.isTranslucent = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        tabBarController?.tabBar.isHidden = false

        ////Hide Clear All Message Button
        clearAllBtn.frame = CGRect(x: 0, y: -topBarHeight, width: UIScreen.main.bounds.size.width, height: topBarHeight)
        clearAllBtn.isHidden = true
        clearAllAnimationInProgress = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("Notifications", comment: "Notifications")

        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName:"backArrow"), style: .plain, target: self, action: #selector(NotificationsViewController.onBackButton))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName:"Settings icon"), style: .plain, target: self, action: #selector(NotificationsViewController.onSettingsButton))

        setupClearAllBtn()
        setupGesturesToTableView()
        
        notificationsComponent.load(tableView: tableView)
    }

    func setupClearAllBtn() {
        let statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        topBarHeight = statusBarHeight + (self.navigationController?.navigationBar.frame.height ?? 0.0)

        clearAllBtn = UIButton(type: .custom)
        clearAllBtn.frame = CGRect(x: 0, y: -topBarHeight, width: UIScreen.main.bounds.size.width, height: topBarHeight)
        clearAllBtn.setTitle(NSLocalizedString("Clear all Notifications", comment: "Notifications"), for: .normal)
        clearAllBtn.setTitleColor(UIColor.white, for: .normal)
        clearAllBtn.backgroundColor = UIColor.themeBlueColor
        clearAllBtn.titleLabel?.font = UIFont(name: "HelveticaNeue-Medium", size: 18)
        clearAllBtn.titleEdgeInsets = UIEdgeInsetsMake(statusBarHeight, 0, 0, 0)
        clearAllBtn.addTarget(self, action: #selector(clearAllBtnAction), for: .touchUpInside)
        clearAllBtn.isHidden = true

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window?.addSubview(clearAllBtn)
    }

    @objc func onBackButton() {
        navigationController?.popViewController(animated: true)
    }

    @objc func onSettingsButton() {
        let storyBoard = UIStoryboard(name: "Menu", bundle: nil)
        let notificationsVC = storyBoard.instantiateViewController(withIdentifier: "NotificationSettingsTableViewController") as! NotificationSettingsTableViewController
        let navController = UINavigationController(rootViewController: notificationsVC)
    
        self.present(navController, animated: true, completion: nil)
    }

    func setupGesturesToTableView() {
        let longPressGestureOnTableView = UILongPressGestureRecognizer.init(target: self, action: #selector(longOnTableView))
        longPressGestureOnTableView.minimumPressDuration = 0.7
        
        tableView.addGestureRecognizer(longPressGestureOnTableView)
    }

    @objc func clearAllBtnAction(_ sender: UIButton) {
        let lastRow = notificationsComponent.count() - 1
        
        notificationsComponent.clear()
        tableView.deleteRows(at: (0...lastRow).map({ IndexPath(row: $0, section: 0) }), with: .fade)
        animateHide()
        
        NotificationsClient.shared.deleteAll()
    }

    @objc func longOnTableView(recognizer: UILongPressGestureRecognizer) {
        switch recognizer.state {
        case .began:
            if !clearAllAnimationInProgress {
                clearAllAnimationInProgress = true
                clearAllBtn?.isHidden = false
                UIView.animate(withDuration: 0.5, animations: { () -> Void in
                    self.clearAllBtn?.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: self.topBarHeight)
                }, completion: { (_ finished: Bool) -> Void in
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(4.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: { () -> Void in
                        if self.clearAllAnimationInProgress {
                            self.animateHide()
                        }
                    })
                })
            }
        default:
            break
        }
    }

    func animateHide() {
        UIView.animate(withDuration: 0.5, animations: { () -> Void in
            self.clearAllBtn?.frame = CGRect(x: 0, y: -self.topBarHeight, width: UIScreen.main.bounds.size.width, height: self.topBarHeight)
        }, completion: { (_ finished: Bool) -> Void in
            self.clearAllBtn.isHidden = true
            self.clearAllAnimationInProgress = false
        })
    }
}

extension NotificationsViewController: UITableViewDelegate, UITableViewDataSource, UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let notification = notificationsComponent.item(at: indexPath) {
            if notification.type == .recordGramNotification {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "recordGramMessageCell", for: indexPath) as? RecordGramMessageTableViewCell else {
                    fatalError()
                }

                cell.setupCell(with: notification)

                return cell
            } else {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "notificationsCell", for: indexPath) as? NotificationTableViewCell else {
                    fatalError()
                }

                cell.setupCell(with: notification)

                return cell
            }
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "notificationsCell", for: indexPath) as? NotificationTableViewCell else {
                fatalError()
            }

            cell.resetCell()

            notificationsComponent.loadDataIfNeeded(for: indexPath, on: tableView)

            return cell
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notificationsComponent.count()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .destructive, title: NSLocalizedString("Delete", comment: "Dialog action")) { (action, indexPath) in
            guard let uuid = self.notificationsComponent.item(at: indexPath)?.uuid else {
                return
            }

            NotificationsClient.shared.delete(uuid: uuid) {
                self.notificationsComponent.clear()

                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }

        delete.backgroundColor = UIColor(hex: "B3215A")

        return [delete]
    }
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach({ notificationsComponent.loadDataIfNeeded(for: $0, on: tableView) })
    }
}
