//
//  GLProgressHUD.swift
//  Toast
//
//  Created by apple on 2021/6/5.
//

import UIKit
import GLToast_Swift

class GLProgressHUD: NSObject {
    
    class func initConfig() {
        // create a new style
        var style = GL_ToastStyle()
        style.cornerRadius = 3
        style.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        style.titleColor = .white
        style.titleFont = .systemFont(ofSize: 14)
        style.titleAlignment = .center
        style.messageColor = .white
        style.messageFont = .systemFont(ofSize: 12)
        style.messageAlignment = .center
        
        style.imageSize = .init(width: 30, height: 30)
        
        /// 全局配置统一样式
        GL_ToastManager.shared.style = style
        /// toast弹框点击隐藏
        GL_ToastManager.shared.isTapToDismissEnabled = true

        /// 多个弹框是否重叠
        GL_ToastManager.shared.isQueueEnabled = false
        GL_ToastManager.shared.duration = 2
        GL_ToastManager.shared.position = .center
    }
    
    /// 显示图片和文字信息
    /// - Parameters:
    ///   - msg: 文字信息
    ///   - tit: 文字信息
    ///   - img: 图片
    ///   - view: 展示View
    class func show(_ msg: String?, tit: String? = nil, img: UIImage? = nil, toView view: UIView? = nil) {
        let showView = view ?? UIApplication.shared.keyWindow
        showView?.gl_makeToast(msg, title: tit, image: img, completion: { didTap in
            if didTap {
                print("GLProgressHUD tap")
            } else {
                print("GLProgressHUD without tap")
            }
        })
    }
    
    
    //MARK: - 图片文字
    /// 显示信息图片和文字信息
    /// - Parameter msg: 文字信息
    class func showInfo(_ msg: String?, tit: String? = nil) {
        show(msg, tit: tit, img: UIImage.init(named: "msg_info"))
    }
    
    /// 显示成功图片和文字信息
    /// - Parameter msg: 文字信息
    class func showSuccess(_ msg: String?, tit: String? = nil) {
        show(msg, tit: tit, img: UIImage.init(named: "msg_success"))
    }
    
    /// 显示错误图片和文字信息
    /// - Parameter msg: 文字信息
    class func showError(_ msg: String?, tit: String? = nil) {
        if (msg ?? "").contains("网络异常，请检查您的网络") {
            NoNetwork()
            return
        }
        if (msg ?? "").contains("暂无数据") {
            return
        }
        show(msg, tit: tit, img: UIImage.init(named: "msg_error"))
    }
    
    //MARK: - 菊花
    /// 菊花
    class func showIndicator(_ msg: String? = nil, tit: String? = nil, toView view: UIView? = nil) {
        let showView = view ?? GLApp?.window
        if let bg = showView?.viewWithTag(921016) {
            bg.gl_makeToastActivity(msg, title: tit)
        } else {
            let bg = UIView.init(frame: showView?.bounds ?? .zero)
            bg.backgroundColor = .clear
            bg.tag = 921016
            showView?.addSubview(bg)
            bg.gl_makeToastActivity(msg, title: tit)
        }
    }
    
    // MARK: - dismiss
    class func dismissAll(_ view: UIView? = nil) {
        let showView = view ?? GLApp?.window
        showView?.gl_hideToastActivity()
        showView?.gl_hideAllToasts()
        showView?.viewWithTag(921016)?.removeFromSuperview()
    }
    
    class func dismissOne(_ view: UIView? = nil) {
        let showView = view ?? GLApp?.window
        showView?.gl_hideToastActivity()
        showView?.gl_hideToast()
        showView?.viewWithTag(921016)?.removeFromSuperview()
    }
}

func NoNetwork() {
    
}
