//
//  SaveMediaViewController.swift
//  RecordGram
//
//  Created by Hugo Prione on 20/11/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit

protocol SaveMediaViewControllerDelegate {
    func didCancel(viewController: SaveMediaViewController)
    func didConfirm(viewController: SaveMediaViewController, media: Media)
}

enum MediaType: String {
    case song = "Song"
    case video = "Video"
}

class SaveMediaViewController: UIViewController, ErrorHandler {
    @IBOutlet weak var viewPopupContainer: UIView! {
        didSet {
            viewPopupContainer.clipsToBounds = true
            viewPopupContainer.layer.borderColor = UIColor.lightGray.cgColor
            viewPopupContainer.layer.borderWidth = 1.0
            viewPopupContainer.layer.cornerRadius = 4.0
        }
    }
    @IBOutlet weak var txtMediaName: UITextField! {
        didSet {
            txtMediaName.tintColor = UIColor(hex: "CA1758")
            txtMediaName.backgroundColor = UIColor.clear

            switch mediaType {
            case .song:
                txtMediaName.placeholder = NSLocalizedString("Type the name of your song here", comment: "Save media hint")
            case .video:
                txtMediaName.placeholder = NSLocalizedString("Type the name of your video here", comment: "Save media hint")
            }
            txtMediaName.delegate = self
        }
    }
    @IBOutlet weak var switchPublic: UISwitch! {
        didSet {
            switchPublic.tintColor = UIColor(hex: "8f9daf")
            switchPublic.layer.cornerRadius = 16;
            switchPublic.backgroundColor = UIColor(hex: "8f9daf")
        }
    }
    @IBOutlet weak var btnChooseContest: UIButton! {
        didSet {
            btnChooseContest.setTitleColor(UIColor(hex: "34455a"), for: .normal)
            btnChooseContest.setTitleColor(UIColor.lightGray, for: .highlighted)
            btnChooseContest.layer.cornerRadius = 4.0
        }
    }
    @IBOutlet weak var btnChooseImage: UIButton! {
        didSet {
            btnChooseImage.setTitleColor(UIColor.gray, for: .normal)
            btnChooseImage.setTitleColor(UIColor.darkGray, for: .highlighted)
            btnChooseImage.layer.cornerRadius = 4.0
        }
    }
    @IBOutlet weak var imgSongThumbnail: UIImageView! {
        didSet {
            imgSongThumbnail.layer.borderColor = UIColor.lightGray.cgColor
            imgSongThumbnail.layer.borderWidth = 0.0
            imgSongThumbnail.clipsToBounds = true
            imgSongThumbnail.isHidden = true
            
            let maskPath = UIBezierPath(roundedRect: imgSongThumbnail.bounds, byRoundingCorners: [.topRight, .bottomRight], cornerRadii: CGSize(width: 4.0, height: 4.0))
            let maskLayer = CAShapeLayer()
            maskLayer.frame = imgSongThumbnail.bounds
            maskLayer.path = maskPath.cgPath
            
            imgSongThumbnail.layer.mask = maskLayer
        }
    }
    @IBOutlet weak var txtDescription: UITextView! {
        didSet{
            txtDescription.delegate = self
        }
    }
    @IBOutlet weak var lblCharacterLimit: UILabel!
    @IBOutlet weak var btnConfirm: UIButton! {
        didSet {
            btnConfirm.setTitleColor(UIColor.white, for: .normal)
            btnConfirm.setTitleColor(UIColor.darkGray, for: .highlighted)
            btnConfirm.layer.cornerRadius = 4.0
        }
    }
    @IBOutlet weak var btnCancel: UIButton! {
        didSet {
            btnCancel.setTitleColor(UIColor.white, for: .normal)
            btnCancel.setTitleColor(UIColor.darkGray, for: .highlighted)
            btnCancel.layer.cornerRadius = 4.0
        }
    }
    @IBOutlet weak var viewContests: UIView! {
        didSet {
            viewContests.isHidden = true
        }
    }
    @IBOutlet weak var colContests: UICollectionView!
    @IBOutlet weak var colHighlightedContests: UICollectionView!
    private lazy var highlightedContests = [Contest]()
    private lazy var contests = [Contest]()
    private var contest: Contest?
    
    var media: Media? {
        didSet {
            // TODO: refactor 2017-11-28
            if let song = media as? Song {
                mediaType = .song
                contest = song.contest
            } else if let video = media as? Video {
                mediaType = .video
                contest = video.contest
            }
            url = media?.url
        }
    }
    var base: Media?
    var url: URL? {
        didSet {
            // TODO: refactor 2017-11-28
            if url?.path.contains(".mp3") == true || url?.path.contains(".m4a") == true  {
                mediaType = .song
            } else if url?.path.contains(".mp4") == true {
                mediaType = .video
            }
        }
    }
    var delegate: SaveMediaViewControllerDelegate?
    private var mediaType: MediaType = .song
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hideKeyboardWhenTappedAround()
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapView))
        gesture.cancelsTouchesInView = false
        view.addGestureRecognizer(gesture)
    }
    
    @objc func didTapView(_ gesture: UIGestureRecognizer) {
        guard gesture.state == .ended else {
            return
        }
        
        viewContests.fadeOut(duration: 0.25, delay: 0.0, completion: { _ in
            self.viewContests.isHidden = true
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        view.alpha = 0.0
        
        // TODO: implement 2017-11-28 (all info)
        btnChooseImage.isHidden = mediaType != .song
        txtMediaName.text = media?.name
        switchPublic.isOn = media?.isPublic ?? true
        txtDescription.text = media?.description
        
        ContestsClient.shared.all(success: { (contests) in
            self.contests = contests ?? []
            self.colContests.reloadData()
            
            self.highlightedContests = Array(self.contests[0..<min(self.contests.count, 4)])
            self.colHighlightedContests.reloadData()
        }, failure: { error in
            self.presentErrorDialog(error: error)
        })
        
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animate(withDuration: 0.3, animations: {
            self.view.alpha = 1
        }, completion: { _ in
            self.txtMediaName.becomeFirstResponder()
        })
    }
    
    // MARK: - IBActions
    
    @IBAction func didTapChooseContestButton(_ sender: Any) {
        viewContests.fadeIn()
    }
    
    @IBAction func didTapChooseImageButton(_ sender: UIButton) {
        let alertController = UIAlertController(title: nil, message: NSLocalizedString("Event Image", comment: "Dialog title"), preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Camera", comment: "Dialog option"), style: .default, handler: { _ in
            self.selectPicture(sourceType: .camera)
        }))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Library", comment: "Dialog option"), style: .default, handler: { _ in
            self.selectPicture(sourceType: .photoLibrary)
        }))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Dialog option"), style: .cancel, handler: nil))
        alertController.popoverPresentationController?.sourceRect = sender.frame
        alertController.popoverPresentationController?.sourceView = sender
        
        present(alertController, animated: true, completion: nil)
    }
    
    func selectPicture(sourceType: UIImagePickerControllerSourceType) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = sourceType == .camera
        imagePickerController.sourceType = sourceType
        imagePickerController.modalPresentationStyle = .overCurrentContext
        present(imagePickerController, animated: true, completion: nil)
    }
    
    // TODO: implement 2017-11-28 (get user's location)
    @IBAction func didTapConfirmButton(_ sender: Any) {
        let optTitle = txtMediaName.text
        let description = txtDescription.text
        let isPublic = switchPublic.isOn
        
        guard var title = optTitle, !title.isEmpty else {
            switch mediaType {
            case .song:
                view.makeToast(NSLocalizedString("Please enter a title for your song", comment: "Form validation"), duration: 3, position: .center)
            case .video:
                view.makeToast(NSLocalizedString("Please enter a title for your video", comment: "Form validation"), duration: 3, position: .center)
            }

            txtMediaName.becomeFirstResponder()
            return
        }
        
        title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !title.isEmpty else {
            switch mediaType {
            case .song:
                view.makeToast(NSLocalizedString("Please enter a valid title for your song", comment: "Form validation"), duration: 3, position: .center)
            case .video:
                view.makeToast(NSLocalizedString("Please enter a valid title for your video", comment: "Form validation"), duration: 3, position: .center)
            }
            txtMediaName.becomeFirstResponder()
            return
        }

        guard title.isValidMediaName() else {
            view.makeToast("Only Letters and Numbers are allowed while naming.", duration: 3, position: .center)
            txtMediaName.becomeFirstResponder()
            return
        }
        
        switch self.mediaType {
        case .song:
            let song = media as? Song ?? Song()
            song.uuid = media?.uuid
            song.name = title
            song.description = description
            song.isPublic = isPublic
            song.beat = base as? Beat
            song.url = url
            song.contest = contest
            song.thumbnailImage = imgSongThumbnail.image
            
            delegate?.didConfirm(viewController: self, media: song)
        case .video:
            let video = media as? Video ?? Video()
            video.uuid = media?.uuid
            video.name = title
            video.description = description
            video.isPublic = isPublic
            video.beat = base as? Beat ?? (base as? Song)?.beat
            video.url = url
            video.contest = contest
            
            delegate?.didConfirm(viewController: self, media: video)
        }
    }
    
    @IBAction func didTapCancelButton(_ sender: Any) {
        delegate?.didCancel(viewController: self)
    }
}

extension SaveMediaViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
}

extension SaveMediaViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text as NSString).rangeOfCharacter(from: CharacterSet.newlines).location == NSNotFound {
            return true
        }
        textView.resignFirstResponder()
        return false
    }
}

extension SaveMediaViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == colContests {
            return contests.count
        } else if collectionView == colHighlightedContests {
            return highlightedContests.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as? ContestCollectionViewCell else {
            fatalError()
        }
        
        var contest: Contest?
        
        if collectionView == colContests {
            contest = contests[indexPath.row]
        } else if collectionView == colHighlightedContests {
            contest = highlightedContests[indexPath.row]
        }
        
        cell.imgCover.kf.setImage(with: contest?.thumbnail, placeholder: #imageLiteral(resourceName: "contest_placeholder"), options: nil, progressBlock: nil, completionHandler: nil)
        cell.viewSelected.isHidden = self.contest?.uuid != contest?.uuid
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == colContests {
            self.contest = contests[indexPath.row]
        } else if collectionView == colHighlightedContests {
            self.contest = highlightedContests[indexPath.row]
        }
        
        colContests.reloadData()
        colHighlightedContests.reloadData()
    }
}

extension SaveMediaViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        guard let image = info[UIImagePickerControllerEditedImage] as? UIImage ?? info[UIImagePickerControllerOriginalImage] as? UIImage else {
            return
        }
        
        imgSongThumbnail.image = image
        imgSongThumbnail.isHidden = false
        
        dismiss(animated: true, completion: nil)
    }
}
