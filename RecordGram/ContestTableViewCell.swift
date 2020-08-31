//
//  ContestTableViewCell.swift
//  RecordGram
//
//  Created by Mauro Taroco on 1/26/18.
//  Copyright © 2018 Meridian Inc. All rights reserved.
//

import UIKit
import Kingfisher

class ContestTableViewCell: UITableViewCell {

    @IBOutlet weak var contestThumbImageView: UIImageView!
    @IBOutlet weak var winnerVideoThumbImageView: UIImageView!
    @IBOutlet weak var transparentView: UIView!
    @IBOutlet weak var titleLabel: UILabel!

    var tapVideoView: ((Contest) -> ())?;
    var tapTransparantView: ((Contest) -> ())?;

    var contest: Contest?

    override func awakeFromNib() {
        super.awakeFromNib()

        backgroundColor = UIColor.clear
        selectionStyle = .none
        winnerVideoThumbImageView.isUserInteractionEnabled = true
        winnerVideoThumbImageView.clipsToBounds = true
        winnerVideoThumbImageView.layer.borderWidth = 1.0
        winnerVideoThumbImageView.layer.borderColor = UIColor.white.cgColor

        setupGestures()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func setupGestures() {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapVideo))
        gesture.cancelsTouchesInView = true
        winnerVideoThumbImageView.addGestureRecognizer(gesture)

        let gesture2 = UITapGestureRecognizer(target: self, action: #selector(didTapTransparent))
        gesture2.cancelsTouchesInView = true
        transparentView.addGestureRecognizer(gesture2)
    }

    func setupCell(withContest contest: Contest) {
        self.contest = contest

        if let thumbnail = contest.thumbnail {
            contestThumbImageView.kf.setImage(with: thumbnail, placeholder: #imageLiteral(resourceName: "gradientButtonBG"))
        }

        //Set Attibuted Title Label
        titleLabel.attributedText = setAttributedTextOnTitleLabelWithInfo(withContest: contest)
        winnerVideoThumbImageView.backgroundColor = UIColor(red: 170 / 255.0, green: 170 / 255.0, blue: 170 / 255.0, alpha: 0.4)
        winnerVideoThumbImageView.isHidden = true

        //Show Or Hide Winner View
        showOrHideWinnerView()
    }

    // MARK:- Gestures events

    @objc func didTapVideo() {
        self.tapVideoView?(contest!)
    }

    @objc func didTapTransparent(gesture: UITapGestureRecognizer) {

        let tapLocation: CGPoint = gesture.location(in: gesture.view)
        gesture.view?.showRippleEffect(onLocation: tapLocation, circleRadius: 100, andWave: UIColor.white)

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.2 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: { () -> Void in
            self.tapTransparantView?(self.contest!)
        })
    }

    // MARK:- Helpers

    func setAttributedTextOnTitleLabelWithInfo(withContest contest: Contest) -> NSMutableAttributedString {
        let titleInfoStr = NSMutableAttributedString(string: contest.title ?? "", attributes: [NSAttributedStringKey.foregroundColor: UIColor.white, NSAttributedStringKey.font: UIFont(name: "HelveticaNeue-Bold", size: 16)!])
        titleInfoStr.append(NSAttributedString(string: """


""", attributes: nil))
        titleInfoStr.append(NSAttributedString(string: "#\(String(describing: contest.hashtag ?? ""))", attributes: [NSAttributedStringKey.foregroundColor: UIColor.white, NSAttributedStringKey.font: UIFont(name: "HelveticaNeue-Bold", size: 28)!]))
        titleInfoStr.append(NSAttributedString(string: """


""", attributes: nil))
        titleInfoStr.append(NSAttributedString(string: ContestTableViewCell.contestEndTimeFormatStr(withContest: contest), attributes: [NSAttributedStringKey.foregroundColor: UIColor.white, NSAttributedStringKey.font: UIFont(name: "HelveticaNeue", size: 18)!]))
        return titleInfoStr
    }

    static func contestEndTimeFormatStr(withContest contest: Contest) -> String {
        guard let endDate = contest.endDate else {
            return ""
        }
        let contestEndTimeStr: String = self.intervalBetweenCurrentTimeAndFutureTimeInterval(endDate.timeIntervalSince1970)
        var formatStr = ""
        if self.contestIsOver(contest) {
            //In case contest already reached its end date OR winner has been declared before end date
            formatStr = String(format: NSLocalizedString("Ended %@ ago", comment: "Contest"), contestEndTimeStr)
        } else if let winnerId = contest.winnerId, winnerId > 0, let winnerType = contest.winnerType, winnerType.count > 0 {
            //In case contest already reached its end date OR winner has been declared before end date
            formatStr = String(format: NSLocalizedString("Ended %@ ago", comment: "Contest"), contestEndTimeStr)
        } else {
            formatStr = String(format: NSLocalizedString("Ends in %@", comment: "Contest"), contestEndTimeStr)
        }
        return formatStr
    }


    static func contestIsOver(_ contest: Contest) -> Bool {
        guard let endDate = contest.endDate else {
            return false
        }
        let intervalCurrentTime: TimeInterval = Date().timeIntervalSince1970
        let intervalContestEndDate = endDate.timeIntervalSince1970
        return intervalContestEndDate < intervalCurrentTime
    }

    static func intervalBetweenCurrentTimeAndFutureTimeInterval(_ futureTimeInterval: TimeInterval) -> String {
        let interval1: TimeInterval = futureTimeInterval
        let interval2: TimeInterval = Date().timeIntervalSince1970
        var difference = Float((interval1 - interval2))
        difference = abs(difference)
        if difference > 59 {
            let minutes = Int((difference / 60))
            if minutes > 59 {
                let hours: Int = minutes / 60
                if hours > 23 {
                    let days: Int = hours / 24
                    if days > 29 {
                        let months: Int = days / 30
                        if months > 11 {
                            let years: Int = months / 12
                            return "\(Int(years)) \(years > 1 ? NSLocalizedString("years", comment: "Contest") : NSLocalizedString("year", comment: "Contest"))"
                        } else {
                            return "\(Int(months)) \(months > 1 ? NSLocalizedString("months", comment: "Contest") : NSLocalizedString("month", comment: "Contest"))"
                        }
                    } else {
                        return "\(Int(days)) \(days > 1 ? NSLocalizedString("days", comment: "Contest") : NSLocalizedString("day", comment: "Contest"))"
                    }
                } else {
                    return "\(Int(hours)) \(hours > 1 ? NSLocalizedString("hours", comment: "Contest") : NSLocalizedString("hour", comment: "Contest"))"
                }
            } else {
                return "\(Int(minutes)) \(minutes > 1 ? NSLocalizedString("minutes", comment: "Contest") : NSLocalizedString("minute", comment: "Contest"))"
            }
        } else {
            if difference <= 1 {
                return NSLocalizedString("Just now", comment: "Contest")
            }
            return "\(Int(difference)) \(difference > 1 ? NSLocalizedString("seconds", comment: "Contest") : NSLocalizedString("second", comment: "Contest"))"
        }
        return ""
    }

    func showOrHideWinnerView() {
        guard let winner = contest?.winner else {
            return
        }

        if let winnerId = contest?.winnerId, winnerId > 0, let winnerType = contest?.winnerType, winnerType.count > 0 {
            if (winner.shared != 0) {
                winnerVideoThumbImageView.isHidden = false
                winnerVideoThumbImageView.image = UIImage(named: "contest_placeholder.png")
                //if (winnerType == ContestType.video) {
                if (winnerType == "video") {
                    if let gif = winner.gif, gif.count > 0 {
                        winnerVideoThumbImageView.kf.setImage(with: URL(string: gif), placeholder: UIImage(named: "video_placeholder"))
                    } else {
                        if let thumb = winner.thumbnail {
                            winnerVideoThumbImageView.kf.setImage(with: thumb, placeholder: UIImage(named: "contest_placeholder.png"))
                        }
                    }
                } else {
                    if let thumb = winner.thumbnail {
                        winnerVideoThumbImageView.kf.setImage(with: thumb, placeholder: UIImage(named: "contest_placeholder.png"))
                    }
                }
            }
        }
    }
}
