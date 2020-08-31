//
//  CommentsViewController.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/19/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import Kingfisher

class CommentsViewController: UIViewController, UITextViewDelegate, ErrorHandler {
    @IBOutlet weak var txtComment: UITextView!
    @IBOutlet weak var btnSend: UIButton! {
        didSet {
            btnSend.layer.borderColor = UIColor.white.cgColor
        }
    }
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.rowHeight = UITableViewAutomaticDimension
            tableView.estimatedRowHeight = 90
        }
    }
    @IBOutlet weak var viewCommentLayoutConstraintBottom: NSLayoutConstraint!

    var media: Media!
    private lazy var comments = [Comment]()

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(keyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)

        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapView))
        gesture.cancelsTouchesInView = true
        view.addGestureRecognizer(gesture)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationController?.setNavigationBarHidden(false, animated: true)

        // TODO: refactor 2017-12-01 (simplify)
        if let _ = media as? Song {
            SongsClient.shared.comments(uuid: media.uuid ?? "", success: { (comments) in
                self.comments = comments ?? []
                self.tableView.reloadData()
            }, failure: { error in
                self.presentErrorDialog(error: error)
            })
        } else if let _ = media as? Video {
            VideosClient.shared.comments(uuid: media.uuid ?? "", success: { (comments) in
                self.comments = comments ?? []
                self.tableView.reloadData()
            }, failure: { error in
                self.presentErrorDialog(error: error)
            })
        }

//        UIApplication.shared.isStatusBarHidden = true

        self.navigationController?.navigationBar.backgroundColor = UIColor.clear
    }

    @objc func didTapView(_ gesture: UIGestureRecognizer) {
        guard gesture.state == .ended else {
            return
        }

        view.endEditing(true)
    }

    @objc func keyboardWillShow(_ notification: Notification) {
        guard let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size else {
            return
        }
        guard let rate = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }

        viewCommentLayoutConstraintBottom.constant = -(keyboardSize.height - (tabBarController?.tabBar.frame.height ?? 0))

        UIView.animate(withDuration: rate, animations: { [weak self] in
            self?.view.layoutIfNeeded()
        })
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        guard let rate = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }

        viewCommentLayoutConstraintBottom.constant = 0

        UIView.animate(withDuration: rate, animations: { [weak self] in
            self?.view.layoutIfNeeded()
        })
    }

    // MARK: - IBActions

    @IBAction func didTapCloseButton(_ sender: Any) {
        if let navigationController = navigationController,
           navigationController.viewControllers.first != self {
            if let song = media as? Song {
                song.comments = comments.count
            }
            if let video = media as? Video {
                video.comments = comments.count
            }

            navigationController.popViewController(animated: true)
        }
    }

    @IBAction func didTapSendButton(_ sender: Any) {
        let comment = Comment(uuid: nil, body: txtComment.text, media: media, user: nil)

        // TODO: refactor 2017-12-01 (simplify)
        if let _ = media as? Song {
            SongsClient.shared.comment(comment: comment, success: { comment in
                guard let comment = comment else {
                    return
                }

                self.comments.append(comment)
                self.tableView.reloadData() // FIXME: 2017-12-01 insert row with animation

                self.scrollToBottom()

                self.txtComment.text = ""
            }, failure: { error in
                self.presentErrorDialog(error: error)
            })
        } else if let _ = media as? Video {
            VideosClient.shared.comment(comment: comment, success: { comment in
                guard let comment = comment else {
                    return
                }

                self.comments.append(comment)
                self.tableView.reloadData() // FIXME: 2017-12-01 insert row with animation

                self.scrollToBottom()

                self.txtComment.text = ""
            }, failure: { error in
                self.presentErrorDialog(error: error)
            })
        }
    }

    func scrollToBottom() {
        let lastItemIndexPath = IndexPath(item: comments.count - 1, section: 0)
        tableView.scrollToRow(at: lastItemIndexPath, at: .top, animated: true)
    }
}

// MARK : TableView Delegate / Datasource

extension CommentsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as? CommentTableViewCell else {
            fatalError()
        }

        let comment = comments[indexPath.row]

        cell.imgProfile.kf.setImage(with: comment.user?.picture, placeholder: #imageLiteral(resourceName:"user_placeholder"), options: nil, progressBlock: nil, completionHandler: nil)
        cell.lblUsername.text = comment.user?.username
        cell.lblBody.text = comment.body

        return cell
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let comment = comments[indexPath.row]

        return comment.user?.uuid == UserClient.shared.uuid()
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            let comment = comments[indexPath.row]

            if let _ = comment.media as? Song {
                SongsClient.shared.delete(comment: comment, success: {
                    self.comments.remove(at: indexPath.row)
                    self.tableView.deleteRows(at: [indexPath], with: .left)
                }, failure: { error in
                    self.presentErrorDialog(error: error)
                })
            } else if let _ = comment.media as? Video {
                VideosClient.shared.delete(comment: comment, success: {
                    self.comments.remove(at: indexPath.row)
                    self.tableView.deleteRows(at: [indexPath], with: .left)
                }, failure: { error in
                    self.presentErrorDialog(error: error)
                })
            }
        default:
            break;
        }
    }
}

extension UIViewController {

    func openComments(with media: Media?) {
        let storyboard = UIStoryboard(name: "Players", bundle: Bundle.main)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "CommentsViewController") as? CommentsViewController else {
            fatalError("Couldn't instantiate CommentsViewController!")
        }

        viewController.media = media

        if let navigationController = navigationController {
            navigationController.pushViewController(viewController, animated: true)
        }
    }
}
