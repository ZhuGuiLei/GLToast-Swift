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
        var style = ToastStyle()
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
        ToastManager.shared.style = style
        /// toast弹框点击隐藏
        ToastManager.shared.isTapToDismissEnabled = true

        /// 多个弹框是否重叠
        ToastManager.shared.isQueueEnabled = false
        ToastManager.shared.duration = 2
        ToastManager.shared.position = .center
    }
    
    /// 显示图片和文字信息
    /// - Parameters:
    ///   - msg: 文字信息
    ///   - tit: 文字信息
    ///   - img: 图片
    ///   - view: 展示View
    class func show(_ msg: String?, tit: String? = nil, img: UIImage? = nil, toView view: UIView? = nil) {
        let showView = view ?? UIApplication.shared.keyWindow
        showView?.makeToast(msg, title: tit, image: img, completion: { didTap in
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
        show(msg, tit: tit, img: UIImage.init(named: "msg_seccess"))
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
        let showView = view ?? UIApplication.shared.keyWindow
        showView?.makeToastActivity(msg, title: tit)
    }
    
    // MARK: - dismiss
    class func dismissAll(_ view: UIView? = nil) {
        let showView = view ?? UIApplication.shared.keyWindow
        showView?.hideAllToasts()
        showView?.hideToastActivity()
    }
    
    class func dismissOne(_ view: UIView? = nil) {
        let showView = view ?? UIApplication.shared.keyWindow
        showView?.hideToast()
        showView?.hideToastActivity()
    }
}

func NoNetwork() {
    
}

/*
/// 提示
class GLProgressHUD: NSObject {

    static var delay: TimeInterval = 2
    
    static let fontSize: CGFloat = 12
    
    class func initConfig() {
                
        // 前景色
        SVProgressHUD.setDefaultStyle(.custom)
        SVProgressHUD.setBackgroundColor(.color(l: UIColor.w51.withAlphaComponent(0.9), d: UIColor.white(67).withAlphaComponent(0.9)))
        SVProgressHUD.setForegroundColor(.white)
        SVProgressHUD.setMaximumDismissTimeInterval(10)
        // 最小尺寸
        SVProgressHUD.setMinimumSize(CGSize(width: 170, height: 80))
        // 圆角
        SVProgressHUD.setCornerRadius(3)
        // 字体大小
        SVProgressHUD.setFont(UIFont.systemFont(ofSize: fontSize))
        // 动画类型
        SVProgressHUD.setDefaultAnimationType(.flat)
        SVProgressHUD.setRingRadius(20)
        SVProgressHUD.setRingNoTextRadius(20)
        // 用户是否可以做其他操作
//        SVProgressHUD.setDefaultMaskType(.clear)
        // 提示图片大小
        SVProgressHUD.setImageViewSize(CGSize.init(width: 28, height: 28))
        SVProgressHUD.setSuccessImage(UIImage.init(asset: Asset.msgSeccess))
        SVProgressHUD.setErrorImage(UIImage.init(asset: Asset.msgError))
//        SVProgressHUD.setInfoImage(UIImage.init(named: "") ?? UIImage.init())
    }
    
    
    
    /// 显示文字信息
    ///
    /// - Parameter msg: 文字信息
    class func show(msg: String?) {
        self.show(msg: msg, to: nil)
    }
    
    class func show(msg: String?, to view: UIView?) {
        var sup: UIView
        if view != nil {
            sup = view!
        } else {
            sup = UIApplication.shared.keyWindow!
        }
        let hud = MBProgressHUD.showAdded(to: sup, animated: true)
        hud.label.text = msg
        hud.label.font = UIFont.systemFont(ofSize: fontSize)
        hud.label.textColor = .white
        hud.contentColor = UIColor.white
        // 背景颜色
        hud.bezelView.color = UIColor.black.withAlphaComponent(0.7)
        for view in hud.bezelView.subviews {
            if view.isKind(of: UIVisualEffectView.self) {
                view.isHidden = true
            }
        }
        // 再设置模式
        hud.mode = .customView
        // 隐藏时候从父控件中移除
        hud.removeFromSuperViewOnHide = true
        // 边距
        hud.margin = 20
        hud.bezelView.cornerRadius = 2
        // 显示时用户可否进行其他操作，NO可以，YES不可以
        hud.isUserInteractionEnabled = false
        // 1秒之后再消失
        hud.hide(animated: true, afterDelay: delay)
    }
    
    static func show(customView view: UIView) {
        self.show(customView: view, to: nil)
    }
    static func show(customView view: UIView, to supview: UIView?) {
        
        var sup: UIView
        if supview != nil {
            sup = supview!
        } else {
            sup = UIApplication.shared.keyWindow!
        }
        let hud = MBProgressHUD.showAdded(to: sup, animated: true)
        hud.customView = view
        
        hud.contentColor = UIColor.white
        // 背景颜色
        hud.bezelView.backgroundColor = UIColor.black
        // 再设置模式
        hud.mode = .customView
        // 隐藏时候从父控件中移除
        hud.removeFromSuperViewOnHide = true
        // 边距
        hud.margin = 20
        // 显示时用户可否进行其他操作，NO可以，YES不可以
        hud.isUserInteractionEnabled = false
        // 1秒之后再消失
        hud.hide(animated: true, afterDelay: delay)
    }
    
    /// 修改文字信息
    ///
    /// - Parameter msg: 文字信息
    class func message(_ msg: String?) {
        SVProgressHUD.setStatus(msg)
    }
    
    
    
    
//MARK: - 进度
    /// 显示进度
    ///
    /// - Parameter progress: 0.0-1.0进度
    class func show(progress: Float) {
        SVProgressHUD.showProgress(progress)
    }
    
    /// 显示进度和文字信息
    ///
    /// - Parameters:
    ///   - progress: 0.0-1.0进度
    ///   - msg: 文字信息
    class func show(progress: Float, msg: String?) {
        SVProgressHUD.showProgress(progress, status: msg)
    }
    
    
    
    
    
    
    
    
}
*/
