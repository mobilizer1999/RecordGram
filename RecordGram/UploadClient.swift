//
//  UploadClient.swift
//  RecordGram
//
//  Created by Hugo Prione on 20/11/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class UploadClient: Client {
    static let shared = UploadClient()
    
    func upload(isPublic: Bool, file: UIImage, success: @escaping (_ uuid: String) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        sessionManager.upload(
            multipartFormData: { multipartFormData in
                multipartFormData.append(String(describing: isPublic.hashValue).data(using: .utf8)!, withName: "public")
                multipartFormData.append("images".data(using: .utf8)!, withName: "type")
                multipartFormData.append(UIImageJPEGRepresentation(file, 1.0)!, withName: "file", fileName: "image.jpg", mimeType: "image/jpg")
        }, to: apiUrl(endpoint: "uploads"), encodingCompletion: { encodingResult in
            switch encodingResult {
            case .success(let upload, _, _):
                upload.uploadProgress { progress in
                    print("Upload Progress: \(progress.fractionCompleted)")
                }
                upload.responseJSON { response in
                    switch response.result {
                    case .success(let result):
                        success(JSON(result)["data"]["uuid"].stringValue)
                    case .failure(let error):
                        self.defaultError(error: error, failure: failure)
                    }
                }
            case .failure(let encodingError):
                self.defaultError(error: encodingError, failure: failure)
            }
        })
    }

    func upload(isPublic: Bool, song: Song, success: @escaping (_ url: URL?) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        guard let url = song.url else {
            return
        }
        sessionManager.upload(
            multipartFormData: { multipartFormData in
                multipartFormData.append(String(describing: isPublic.hashValue).data(using: .utf8)!, withName: "public")
                multipartFormData.append("songs".data(using: .utf8)!, withName: "type")
                multipartFormData.append(url, withName: "file", fileName: "song.m4a", mimeType: "audio/mp4")
        }, to: apiUrl(endpoint: "uploads"), encodingCompletion: { encodingResult in
            switch encodingResult {
            case .success(let upload, _, _):
                upload.uploadProgress { progress in
                    print("Upload Progress: \(progress.fractionCompleted)")
                }
                upload.responseJSON { response in
                    switch response.result {
                    case .success(let result):
                        success(JSON(result)["data"]["url"].url)
                    case .failure(let error):
                        self.defaultError(error: error, failure: failure)
                    }
                }
            case .failure(let encodingError):
                self.defaultError(error: encodingError, failure: failure)
            }
        })
    }
}
