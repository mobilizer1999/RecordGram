//
//  VideoCollectionViewCell.swift
//  RecordGram
//
//  Created by Hugo Prione on 21/09/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.

import UIKit
import Kingfisher
import Gifu

class VideoCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imgPreview: AnimatedImageView!
    
    var downloadTask: RetrieveImageDownloadTask?
    var retrieveTask: RetrieveImageDiskTask?
    var key: String?
    
    let processor = DefaultImageProcessor.default
    let imageCache = ImageCache.default
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func loadImg(for video: Video) {
        guard let uuid = video.uuid else {
            return
        }
        
        if let url = video.gif {
            key = "\(uuid)-gif"
            
            loadImg(url: url)
        } else if let url = video.thumb {
            key = "\(uuid)-thumb"
            
            loadImg(url: url)
        }
    }
    
    func loadImg(url: URL) {
        guard let key = self.key else {
            return
        }
        
        retrieveTask?.cancel()
        retrieveTask = nil
        
        downloadTask?.cancel()
        downloadTask = nil
        
        retrieveTask = imageCache.retrieveImage(forKey: key, options: [.processor(processor)]) { (image, cache) in
            self.retrieveTask = nil
            
            if let image = image {
                self.imgPreview.image = image
                
                return
            }
            
            self.downloadTask = ImageDownloader.default.downloadImage(with: url, options: [.processor(self.processor)], progressBlock: nil) { image, error, url, data in
                self.downloadTask = nil
                
                guard let image = image else {
                    return
                }
                
                self.imageCache.store(image, original: data, forKey: key, processorIdentifier: self.processor.identifier)
                
                guard self.key == key else {
                    return
                }
                
                self.imgPreview.image = image
            }
        }
    }
}
