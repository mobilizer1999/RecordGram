//
//  UIView+Loading.swift
//  RecordGram
//
//  Created by Nicolas Gonzalez on 3/6/18.
//  Copyright © 2018 Meridian Inc. All rights reserved.
//

import UIKit
import SnapKit
import Gifu
import Kingfisher

extension UIView {

    private struct Keys {
        static var loading = "loading"
    }

    func loading(with message: String? = nil, _ completion: (() -> Void)? = nil) {
        guard objc_getAssociatedObject(self, &Keys.loading) as? UIView == nil else {
            return
        }
        isUserInteractionEnabled = false
        let blurEffect = UIBlurEffect(style: .extraLight)
        let loadingView = UIVisualEffectView(effect: blurEffect)
        loadingView.frame = UIScreen.main.bounds
        loadingView.alpha = 0
        let imageView = UIImageView(gif: "smaller")
        loadingView.contentView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.width.height.equalTo(100)
            make.center.equalToSuperview()
        }
        if let message = message {
            let label = UILabel()
            label.text = message
            label.textColor = UIColor(hex: "581E4F")
            loadingView.contentView.addSubview(label)
            label.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalTo(imageView.snp.bottom).offset(13)
            }
        }

        UIApplication.shared.keyWindow?.addSubview(loadingView)
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut, animations: {
            loadingView.alpha = 1.0
        }) { _ in
            completion?()
        }
        objc_setAssociatedObject(self, &Keys.loading, loadingView, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    func loaded(_ completion: (() -> Void)? = nil) {
        isUserInteractionEnabled = true
        if let loadingView = objc_getAssociatedObject(self, &Keys.loading) as? UIView {
            UIView.animate(withDuration: 0.2, delay: 0.0, options: [.curveEaseIn, .beginFromCurrentState], animations: {
                loadingView.alpha = 0.0
            }) { _ in
                loadingView.removeFromSuperview()
                objc_setAssociatedObject(self, &Keys.loading, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                completion?()
            }
        }
    }
}
