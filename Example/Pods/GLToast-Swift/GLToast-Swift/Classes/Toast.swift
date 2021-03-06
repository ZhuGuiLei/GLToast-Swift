//
//  Toast.swift
//  Toast-Swift
//
//  Created by apple on 2021/6/5.
//  1.2.8

import UIKit
import ObjectiveC

/**
 Toast is a Swift extension that adds toast notifications to the `UIView` object class.
 It is intended to be simple, lightweight, and easy to use. Most toast notifications 
 can be triggered with a single line of code.
 
 The `makeToast` methods create a new view and then display it as toast.
 
 The `showToast` methods display any view as toast.
 
 */
public extension UIView {
    
    /**
     Keys used for associated objects.
     */
    private struct ToastKeys {
        static var timer        = "com.toast-swift.timer"
        static var duration     = "com.toast-swift.duration"
        static var point        = "com.toast-swift.point"
        static var completion   = "com.toast-swift.completion"
        static var activeToasts = "com.toast-swift.activeToasts"
        static var activityView = "com.toast-swift.activityView"
        static var queue        = "com.toast-swift.queue"
    }
    
    /**
     Swift closures can't be directly associated with objects via the
     Objective-C runtime, so the (ugly) solution is to wrap them in a
     class that can be used with associated objects.
     */
    private class ToastCompletionWrapper {
        let completion: ((Bool) -> Void)?
        
        init(_ completion: ((Bool) -> Void)?) {
            self.completion = completion
        }
    }
    
    private enum ToastError: Error {
        case missingParameters
    }
    
    private var activeToasts: NSMutableArray {
        get {
            if let activeToasts = objc_getAssociatedObject(self, &ToastKeys.activeToasts) as? NSMutableArray {
                return activeToasts
            } else {
                let activeToasts = NSMutableArray()
                objc_setAssociatedObject(self, &ToastKeys.activeToasts, activeToasts, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return activeToasts
            }
        }
    }
    
    private var queue: NSMutableArray {
        get {
            if let queue = objc_getAssociatedObject(self, &ToastKeys.queue) as? NSMutableArray {
                return queue
            } else {
                let queue = NSMutableArray()
                objc_setAssociatedObject(self, &ToastKeys.queue, queue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return queue
            }
        }
    }
    
    // MARK: - Make Toast Methods
    
    /// ????????????
    /// - Parameters:
    ///   - message: ??????
    ///   - duration: ??????
    ///   - position: ??????
    ///   - title: ??????
    ///   - image: ??????
    ///   - style: ??????
    ///   - completion: ????????????
    func gl_makeToast(_ message: String?, duration: TimeInterval = GL_ToastManager.shared.duration, position: ToastPosition = GL_ToastManager.shared.position, title: String? = nil, image: UIImage? = nil, style: GL_ToastStyle = GL_ToastManager.shared.style, completion: ((_ didTap: Bool) -> Void)? = nil) {
        do {
            let toast = try toastViewForMessage(message, title: title, image: image, style: style)
            gl_showToast(toast, duration: duration, position: position, completion: completion)
        } catch ToastError.missingParameters {
            print("Error: message, title, and image are all nil")
        } catch {}
    }
    
    /// ????????????
    /// - Parameters:
    ///   - message: ??????
    ///   - duration: ??????
    ///   - point: ??????
    ///   - title: ??????
    ///   - image: ??????
    ///   - style: ??????
    ///   - completion: ????????????
    func gl_makeToast(_ message: String?, duration: TimeInterval = GL_ToastManager.shared.duration, point: CGPoint, title: String?, image: UIImage?, style: GL_ToastStyle = GL_ToastManager.shared.style, completion: ((_ didTap: Bool) -> Void)?) {
        do {
            let toast = try toastViewForMessage(message, title: title, image: image, style: style)
            gl_showToast(toast, duration: duration, point: point, completion: completion)
        } catch ToastError.missingParameters {
            print("Error: message, title, and image cannot all be nil")
        } catch {}
    }
    
    // MARK: - Show Toast Methods
    
    /// ?????????????????????
    /// - Parameters:
    ///   - toast: ????????????
    ///   - duration: ??????
    ///   - position: ??????
    ///   - completion: ????????????
    func gl_showToast(_ toast: UIView, duration: TimeInterval = GL_ToastManager.shared.duration, position: ToastPosition = GL_ToastManager.shared.position, completion: ((_ didTap: Bool) -> Void)? = nil) {
        let point = position.centerPoint(forToast: toast, inSuperview: self)
        gl_showToast(toast, duration: duration, point: point, completion: completion)
    }
    
    /// ?????????????????????
    /// - Parameters:
    ///   - toast: ????????????
    ///   - duration: ??????
    ///   - point: ??????
    ///   - completion: ????????????
    func gl_showToast(_ toast: UIView, duration: TimeInterval = GL_ToastManager.shared.duration, point: CGPoint, completion: ((_ didTap: Bool) -> Void)? = nil) {
        objc_setAssociatedObject(toast, &ToastKeys.completion, ToastCompletionWrapper(completion), .OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        if GL_ToastManager.shared.isQueueEnabled, activeToasts.count > 0 {
            objc_setAssociatedObject(toast, &ToastKeys.duration, NSNumber(value: duration), .OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(toast, &ToastKeys.point, NSValue(cgPoint: point), .OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            
            queue.add(toast)
        } else {
            showToast(toast, duration: duration, point: point)
        }
    }
    
    // MARK: - Hide Toast Methods
    
    /**
     Hides the active toast. If there are multiple toasts active in a view, this method
     hides the oldest toast (the first of the toasts to have been presented).
     
     @see `hideAllToasts()` to remove all active toasts from a view.
     
     @warning This method has no effect on activity toasts. Use `hideToastActivity` to
     hide activity toasts.
     
    */
    func gl_hideToast() {
        guard let activeToast = activeToasts.firstObject as? UIView else { return }
        gl_hideToast(activeToast)
    }
    
    /**
     Hides an active toast.
     
     @param toast The active toast view to dismiss. Any toast that is currently being displayed
     on the screen is considered active.
     
     @warning this does not clear a toast view that is currently waiting in the queue.
     */
    func gl_hideToast(_ toast: UIView) {
        guard activeToasts.contains(toast) else { return }
        hideToast(toast, fromTap: false)
    }
    
    /**
     Hides all toast views.
     
     @param includeActivity If `true`, toast activity will also be hidden. Default is `false`.
     @param clearQueue If `true`, removes all toast views from the queue. Default is `true`.
    */
    func gl_hideAllToasts(includeActivity: Bool = false, clearQueue: Bool = true) {
        if clearQueue {
            gl_clearToastQueue()
        }
        
        activeToasts.compactMap { $0 as? UIView }
                    .forEach { gl_hideToast($0) }
        
        if includeActivity {
            gl_hideToastActivity()
        }
    }
    
    /**
     Removes all toast views from the queue. This has no effect on toast views that are
     active. Use `hideAllToasts(clearQueue:)` to hide the active toasts views and clear
     the queue.
     */
    func gl_clearToastQueue() {
        queue.removeAllObjects()
    }
    
    // MARK: - Activity Methods
    
    /// ?????????????????????
    /// - Parameters:
    ///   - message: ??????
    ///   - title: ??????
    ///   - position: ??????
    func gl_makeToastActivity(_ message: String?, title: String?, position: ToastPosition = GL_ToastManager.shared.position) {
        // sanity
        if let toast = objc_getAssociatedObject(self, &ToastKeys.activityView) as? UIView {
            toast.alpha = 0.0
            toast.removeFromSuperview()
            objc_setAssociatedObject(self, &ToastKeys.activityView, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        
        let toast = createToastActivityView(message, title: title)
        let point = position.centerPoint(forToast: toast, inSuperview: self)
        makeToastActivity(toast, point: point)
    }
    
    /// ?????????????????????
    /// - Parameters:
    ///   - position: ??????
    func gl_makeToastActivity(_ position: ToastPosition) {
        // sanity
        if let toast = objc_getAssociatedObject(self, &ToastKeys.activityView) as? UIView {
            toast.alpha = 0.0
            toast.removeFromSuperview()
            objc_setAssociatedObject(self, &ToastKeys.activityView, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        
        let toast = createToastActivityView()
        let point = position.centerPoint(forToast: toast, inSuperview: self)
        makeToastActivity(toast, point: point)
    }
    
    /// ?????????????????????
    /// - Parameters:
    ///   - message: ??????
    ///   - title: ??????
    ///   - point: ??????
    func gl_makeToastActivity(_ message: String?, title: String?, point: CGPoint) {
        // sanity
        if let toast = objc_getAssociatedObject(self, &ToastKeys.activityView) as? UIView {
            toast.alpha = 0.0
            toast.removeFromSuperview()
            objc_setAssociatedObject(self, &ToastKeys.activityView, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        
        let toast = createToastActivityView(message, title: title)
        makeToastActivity(toast, point: point)
    }
    
    /// ?????????????????????
    /// - Parameters:
    ///   - point: ??????
    func gl_makeToastActivity(_ point: CGPoint) {
        // sanity
        if let toast = objc_getAssociatedObject(self, &ToastKeys.activityView) as? UIView {
            toast.alpha = 0.0
            toast.removeFromSuperview()
            objc_setAssociatedObject(self, &ToastKeys.activityView, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        
        let toast = createToastActivityView()
        makeToastActivity(toast, point: point)
    }
    
    /// ???????????????????????????
    func gl_hideToastActivity() {
        if let toast = objc_getAssociatedObject(self, &ToastKeys.activityView) as? UIView {
            UIView.animate(withDuration: GL_ToastManager.shared.style.fadeDuration, delay: 0.0, options: [.curveEaseIn, .beginFromCurrentState], animations: {
                toast.alpha = 0.0
            }) { _ in
                toast.removeFromSuperview()
                objc_setAssociatedObject(self, &ToastKeys.activityView, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
    
    // MARK: - Private Activity Methods
    
    private func makeToastActivity(_ toast: UIView, point: CGPoint) {
        toast.alpha = 0.0
        toast.center = point
        
        objc_setAssociatedObject(self, &ToastKeys.activityView, toast, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        self.addSubview(toast)
        
        UIView.animate(withDuration: GL_ToastManager.shared.style.fadeDuration, delay: 0.0, options: .curveEaseOut, animations: {
            toast.alpha = 1.0
        })
    }
    
    private func createToastActivityView() -> UIView {
        let style = GL_ToastManager.shared.style
        
        let activityView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: style.activitySize.width, height: style.activitySize.height))
        activityView.backgroundColor = style.activityBackgroundColor
        activityView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        activityView.layer.cornerRadius = style.cornerRadius
        
        if style.displayShadow {
            activityView.layer.shadowColor = style.shadowColor.cgColor
            activityView.layer.shadowOpacity = style.shadowOpacity
            activityView.layer.shadowRadius = style.shadowRadius
            activityView.layer.shadowOffset = style.shadowOffset
        }
        
        let activityIndicatorView = UIActivityIndicatorView.init(style: .whiteLarge)
        activityIndicatorView.center = CGPoint(x: activityView.bounds.size.width / 2.0, y: activityView.bounds.size.height / 2.0)
        activityView.addSubview(activityIndicatorView)
        activityIndicatorView.color = style.activityIndicatorColor
        activityIndicatorView.startAnimating()
        
        return activityView
    }
    
    private func createToastActivityView(_ message: String?, title: String?) -> UIView {
        let style = GL_ToastManager.shared.style
        
        var messageLabel: UILabel?
        var titleLabel: UILabel?
        
        let wrapperView = UIView()
        wrapperView.backgroundColor = style.activityBackgroundColor
        wrapperView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        wrapperView.layer.cornerRadius = style.cornerRadius
        
        if style.displayShadow {
            wrapperView.layer.shadowColor = style.shadowColor.cgColor
            wrapperView.layer.shadowOpacity = style.shadowOpacity
            wrapperView.layer.shadowRadius = style.shadowRadius
            wrapperView.layer.shadowOffset = style.shadowOffset
        }
        
        let activityIndicatorView = UIActivityIndicatorView.init(style: .whiteLarge)
        activityIndicatorView.frame = CGRect(x: 0, y: 0, width: 37, height: 37)
        activityIndicatorView.color = style.activityIndicatorColor
        activityIndicatorView.startAnimating()
        
        var imageRect = CGRect.zero
        
        imageRect.origin.x = style.horizontalPadding
        imageRect.origin.y = style.verticalPadding
        imageRect.size.width = activityIndicatorView.bounds.size.width
        imageRect.size.height = activityIndicatorView.bounds.size.height
        
        if let title = title {
            titleLabel = UILabel()
            titleLabel?.numberOfLines = style.titleNumberOfLines
            titleLabel?.font = style.titleFont
            titleLabel?.textAlignment = style.titleAlignment
            titleLabel?.lineBreakMode = .byTruncatingTail
            titleLabel?.textColor = style.titleColor
            titleLabel?.backgroundColor = UIColor.clear
            titleLabel?.text = title;
            
            let maxTitleSize = CGSize(width: self.bounds.size.width * style.maxWidthPercentage, height: self.bounds.size.height * style.maxHeightPercentage - imageRect.size.height)
            let titleSize = titleLabel?.sizeThatFits(maxTitleSize)
            if let titleSize = titleSize {
                let actualWidth = min(titleSize.width, maxTitleSize.width)
                let actualHeight = min(titleSize.height, maxTitleSize.height)
                titleLabel?.frame = CGRect(x: 0.0, y: 0.0, width: actualWidth, height: actualHeight)
            }
        }
        
        if let message = message {
            messageLabel = UILabel()
            messageLabel?.text = message
            messageLabel?.numberOfLines = style.messageNumberOfLines
            messageLabel?.font = style.messageFont
            messageLabel?.textAlignment = style.messageAlignment
            messageLabel?.lineBreakMode = .byTruncatingTail;
            messageLabel?.textColor = style.messageColor
            messageLabel?.backgroundColor = UIColor.clear
            
            let maxMessageSize = CGSize(width: self.bounds.size.width * style.maxWidthPercentage, height: self.bounds.size.height * style.maxHeightPercentage - imageRect.size.width)
            let messageSize = messageLabel?.sizeThatFits(maxMessageSize)
            if let messageSize = messageSize {
                let actualWidth = min(messageSize.width, maxMessageSize.width)
                let actualHeight = min(messageSize.height, maxMessageSize.height)
                messageLabel?.frame = CGRect(x: 0.0, y: 0.0, width: actualWidth, height: actualHeight)
            }
        }
  
        var titleRect = CGRect.zero
        
        if let titleLabel = titleLabel {
            titleRect.origin.x = style.horizontalPadding
            titleRect.origin.y = imageRect.maxY + style.verticalSpace
            titleRect.size.width = titleLabel.bounds.size.width
            titleRect.size.height = titleLabel.bounds.size.height
        }
        
        var messageRect = CGRect.zero
        
        if let messageLabel = messageLabel {
            messageRect.origin.x = style.horizontalPadding
            let longerHeight = max(titleRect.maxY, imageRect.maxY)
            messageRect.origin.y = longerHeight + style.verticalSpace
            messageRect.size.width = messageLabel.bounds.size.width
            messageRect.size.height = messageLabel.bounds.size.height
        }
        
        let wrapperWidth = max(imageRect.maxX, titleRect.maxX, messageRect.maxX) + style.horizontalPadding
        let wrapperHeight = max(imageRect.maxY, titleRect.maxY, messageRect.maxY) + style.verticalPadding
        
        wrapperView.frame = CGRect(x: 0.0, y: 0.0, width: wrapperWidth, height: wrapperHeight)
        
        if let titleLabel = titleLabel {
            titleRect.size.width = max(imageRect.size.width, titleRect.size.width, messageRect.size.width)
            titleLabel.frame = titleRect
            wrapperView.addSubview(titleLabel)
        }
        
        if let messageLabel = messageLabel {
            messageRect.size.width = max(imageRect.size.width, titleRect.size.width, messageRect.size.width)
            messageLabel.frame = messageRect
            wrapperView.addSubview(messageLabel)
        }
        
        imageRect.origin.x = (wrapperWidth - imageRect.width) * 0.5
        activityIndicatorView.frame = imageRect
        wrapperView.addSubview(activityIndicatorView)
        
        return wrapperView
    }
    
    // MARK: - Private Show/Hide Methods
    
    private func showToast(_ toast: UIView, duration: TimeInterval, point: CGPoint) {
        toast.center = point
        toast.alpha = 0.0
        
        if GL_ToastManager.shared.isTapToDismissEnabled {
            let recognizer = UITapGestureRecognizer(target: self, action: #selector(UIView.handleToastTapped(_:)))
            toast.addGestureRecognizer(recognizer)
            toast.isUserInteractionEnabled = true
            toast.isExclusiveTouch = true
        }
        
        activeToasts.add(toast)
        self.addSubview(toast)
        
        UIView.animate(withDuration: GL_ToastManager.shared.style.fadeDuration, delay: 0.0, options: [.curveEaseOut, .allowUserInteraction], animations: {
            toast.alpha = 1.0
        }) { _ in
            let timer = Timer(timeInterval: duration, target: self, selector: #selector(UIView.toastTimerDidFinish(_:)), userInfo: toast, repeats: false)
            RunLoop.main.add(timer, forMode: .common)
            objc_setAssociatedObject(toast, &ToastKeys.timer, timer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    private func hideToast(_ toast: UIView, fromTap: Bool) {
        if let timer = objc_getAssociatedObject(toast, &ToastKeys.timer) as? Timer {
            timer.invalidate()
        }
        
        UIView.animate(withDuration: GL_ToastManager.shared.style.fadeDuration, delay: 0.0, options: [.curveEaseIn, .beginFromCurrentState], animations: {
            toast.alpha = 0.0
        }) { _ in
            toast.removeFromSuperview()
            self.activeToasts.remove(toast)
            
            if let wrapper = objc_getAssociatedObject(toast, &ToastKeys.completion) as? ToastCompletionWrapper, let completion = wrapper.completion {
                completion(fromTap)
            }
            
            if let nextToast = self.queue.firstObject as? UIView, let duration = objc_getAssociatedObject(nextToast, &ToastKeys.duration) as? NSNumber, let point = objc_getAssociatedObject(nextToast, &ToastKeys.point) as? NSValue {
                self.queue.removeObject(at: 0)
                self.showToast(nextToast, duration: duration.doubleValue, point: point.cgPointValue)
            }
        }
    }
    
    // MARK: - Events
    
    @objc
    private func handleToastTapped(_ recognizer: UITapGestureRecognizer) {
        guard let toast = recognizer.view else { return }
        hideToast(toast, fromTap: true)
    }
    
    @objc
    private func toastTimerDidFinish(_ timer: Timer) {
        guard let toast = timer.userInfo as? UIView else { return }
        gl_hideToast(toast)
    }
    
    // MARK: - Toast Construction
    
    /**
     Creates a new toast view with any combination of message, title, and image.
     The look and feel is configured via the style. Unlike the `makeToast` methods,
     this method does not present the toast view automatically. One of the `showToast`
     methods must be used to present the resulting view.
    
     @warning if message, title, and image are all nil, this method will throw
     `ToastError.missingParameters`
    
     @param message The message to be displayed
     @param title The title
     @param image The image
     @param style The style. The shared style will be used when nil
     @throws `ToastError.missingParameters` when message, title, and image are all nil
     @return The newly created toast view
    */
    private func toastViewForMessage(_ message: String?, title: String?, image: UIImage?, style: GL_ToastStyle) throws -> UIView {
        // sanity
        guard message != nil || title != nil || image != nil else {
            throw ToastError.missingParameters
        }
        
        var messageLabel: UILabel?
        var titleLabel: UILabel?
        var imageView: UIImageView?
        
        let wrapperView = UIView()
        wrapperView.backgroundColor = style.backgroundColor
        wrapperView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        wrapperView.layer.cornerRadius = style.cornerRadius
        
        if style.displayShadow {
            wrapperView.layer.shadowColor = UIColor.black.cgColor
            wrapperView.layer.shadowOpacity = style.shadowOpacity
            wrapperView.layer.shadowRadius = style.shadowRadius
            wrapperView.layer.shadowOffset = style.shadowOffset
        }
        
        if let image = image {
            imageView = UIImageView(image: image)
            imageView?.contentMode = .scaleAspectFit
            imageView?.frame = CGRect(x: 0, y: 0, width: style.imageSize.width, height: style.imageSize.height)
        }
        
        var imageRect = CGRect.zero
        
        if let imageView = imageView {
            imageRect.origin.x = style.horizontalPadding
            imageRect.origin.y = style.verticalPadding
            imageRect.size.width = imageView.bounds.size.width
            imageRect.size.height = imageView.bounds.size.height
        }

        if let title = title {
            titleLabel = UILabel()
            titleLabel?.numberOfLines = style.titleNumberOfLines
            titleLabel?.font = style.titleFont
            titleLabel?.textAlignment = style.titleAlignment
            titleLabel?.lineBreakMode = .byTruncatingTail
            titleLabel?.textColor = style.titleColor
            titleLabel?.backgroundColor = UIColor.clear
            titleLabel?.text = title;
            
            let maxTitleSize = CGSize(width: self.bounds.size.width * style.maxWidthPercentage, height: self.bounds.size.height * style.maxHeightPercentage - imageRect.size.height)
            let titleSize = titleLabel?.sizeThatFits(maxTitleSize)
            if let titleSize = titleSize {
                let actualWidth = min(titleSize.width, maxTitleSize.width)
                let actualHeight = min(titleSize.height, maxTitleSize.height)
                titleLabel?.frame = CGRect(x: 0.0, y: 0.0, width: actualWidth, height: actualHeight)
            }
        }
        
        if let message = message {
            messageLabel = UILabel()
            messageLabel?.text = message
            messageLabel?.numberOfLines = style.messageNumberOfLines
            messageLabel?.font = style.messageFont
            messageLabel?.textAlignment = style.messageAlignment
            messageLabel?.lineBreakMode = .byTruncatingTail;
            messageLabel?.textColor = style.messageColor
            messageLabel?.backgroundColor = UIColor.clear
            
            let maxMessageSize = CGSize(width: self.bounds.size.width * style.maxWidthPercentage, height: self.bounds.size.height * style.maxHeightPercentage - imageRect.size.width)
            let messageSize = messageLabel?.sizeThatFits(maxMessageSize)
            if let messageSize = messageSize {
                let actualWidth = min(messageSize.width, maxMessageSize.width)
                let actualHeight = min(messageSize.height, maxMessageSize.height)
                messageLabel?.frame = CGRect(x: 0.0, y: 0.0, width: actualWidth, height: actualHeight)
            }
        }
  
        var titleRect = CGRect.zero
        
        if let titleLabel = titleLabel {
            titleRect.origin.x = style.horizontalPadding
            titleRect.origin.y = max(imageRect.maxY + style.verticalSpace, style.verticalPadding)
            titleRect.size.width = titleLabel.bounds.size.width
            titleRect.size.height = titleLabel.bounds.size.height
        }
        
        var messageRect = CGRect.zero
        
        if let messageLabel = messageLabel {
            messageRect.origin.x = style.horizontalPadding
            let longerHeight = max(titleRect.maxY, imageRect.maxY)
            messageRect.origin.y = max(longerHeight + style.verticalSpace, style.verticalPadding)
            messageRect.size.width = messageLabel.bounds.size.width
            messageRect.size.height = messageLabel.bounds.size.height
        }
        
        let wrapperWidth = max(imageRect.maxX, titleRect.maxX, messageRect.maxX) + style.horizontalPadding
        let wrapperHeight = max(imageRect.maxY, titleRect.maxY, messageRect.maxY) + style.verticalPadding
        
        wrapperView.frame = CGRect(x: 0.0, y: 0.0, width: wrapperWidth, height: wrapperHeight)
        
        if let titleLabel = titleLabel {
            titleRect.size.width = max(imageRect.size.width, titleRect.size.width, messageRect.size.width)
            titleLabel.frame = titleRect
            wrapperView.addSubview(titleLabel)
        }
        
        if let messageLabel = messageLabel {
            messageRect.size.width = max(imageRect.size.width, titleRect.size.width, messageRect.size.width)
            messageLabel.frame = messageRect
            wrapperView.addSubview(messageLabel)
        }
        
        if let imageView = imageView {
            imageRect.origin.x = (wrapperWidth - imageRect.width) * 0.5
            imageView.frame = imageRect
            wrapperView.addSubview(imageView)
        }
        
        return wrapperView
    }
    
}

// MARK: - Toast Style

/**
 `GL_ToastStyle` instances define the look and feel for toast views created via the
 `makeToast` methods as well for toast views created directly with
 `toastViewForMessage(message:title:image:style:)`.

 @warning `GL_ToastStyle` offers relatively simple styling options for the default
 toast view. If you require a toast view with more complex UI, it probably makes more
 sense to create your own custom UIView subclass and present it with the `showToast`
 methods.
*/
public struct GL_ToastStyle {

    public init() {}
    
    /**
     ?????????. Default is `.black` at 80% opacity.
    */
    public var backgroundColor: UIColor = UIColor.black.withAlphaComponent(0.8)
    
    /**
     ?????????. Default is `UIColor.whiteColor()`.
    */
    public var titleColor: UIColor = .white
    
    /**
     ?????????. Default is `.white`.
    */
    public var messageColor: UIColor = .white
    
    /**
     A percentage value from 0.0 to 1.0, representing the maximum width of the toast
     view relative to it's superview. Default is 0.8 (80% of the superview's width).
    */
    public var maxWidthPercentage: CGFloat = 0.8 {
        didSet {
            maxWidthPercentage = max(min(maxWidthPercentage, 1.0), 0.0)
        }
    }
    
    /**
     A percentage value from 0.0 to 1.0, representing the maximum height of the toast
     view relative to it's superview. Default is 0.8 (80% of the superview's height).
    */
    public var maxHeightPercentage: CGFloat = 0.8 {
        didSet {
            maxHeightPercentage = max(min(maxHeightPercentage, 1.0), 0.0)
        }
    }
    
    /// ???????????? Default is 10.0.
    public var horizontalPadding: CGFloat = 26.0
    
    /// ???????????? Default is 10.0.
    public var verticalPadding: CGFloat = 16.0
    
    /// ???????????? Default is 10.0.
    public var horizontalSpace: CGFloat = 10.0
    
    /// ???????????? Default is 10.0.
    public var verticalSpace: CGFloat = 10.0
    
    /**
     ??????. Default is 4.0.
    */
    public var cornerRadius: CGFloat = 4.0;
    
    /**
     ????????????. Default is `.boldSystemFont(15.0)`.
    */
    public var titleFont: UIFont = .boldSystemFont(ofSize: 15.0)
    
    /**
     ????????????. Default is `.systemFont(ofSize: 13.0)`.
    */
    public var messageFont: UIFont = .systemFont(ofSize: 13.0)
    
    /**
     The title text alignment. Default is `NSTextAlignment.center`.
    */
    public var titleAlignment: NSTextAlignment = .center
    
    /**
     The message text alignment. Default is `NSTextAlignment.center`.
    */
    public var messageAlignment: NSTextAlignment = .center
    
    /**
     The maximum number of lines for the title. The default is 0 (no limit).
    */
    public var titleNumberOfLines = 0
    
    /**
     The maximum number of lines for the message. The default is 0 (no limit).
    */
    public var messageNumberOfLines = 0
    
    /**
     ????????????. Default is `false`.
    */
    public var displayShadow = false
    
    /**
     ?????????. Default is `.black`.
     */
    public var shadowColor: UIColor = .black
    
    /**
     ????????????????????? 0.0 to 1.0. Default is 0.8 (80% opacity).
    */
    public var shadowOpacity: Float = 0.8 {
        didSet {
            shadowOpacity = max(min(shadowOpacity, 1.0), 0.0)
        }
    }

    /**
     The shadow radius. Default is 6.0.
    */
    public var shadowRadius: CGFloat = 6.0
    
    /**
     The shadow offset. The default is 4 x 4.
    */
    public var shadowOffset = CGSize(width: 4.0, height: 4.0)
    
    /**
     The image size. The default is 40 x 40.
    */
    public var imageSize = CGSize(width: 40.0, height: 40.0)
    
    /**
     The size of the toast activity view when `makeToastActivity(position:)` is called.
     Default is 100 x 100.
    */
    public var activitySize = CGSize(width: 80.0, height: 80.0)
    
    /**
     The fade in/out animation duration. Default is 0.2.
     */
    public var fadeDuration: TimeInterval = 0.2
    
    /**
     Activity indicator color. Default is `.white`.
     */
    public var activityIndicatorColor: UIColor = .white
    
    /**
     Activity background color. Default is `.black` at 80% opacity.
     */
    public var activityBackgroundColor: UIColor = UIColor.black.withAlphaComponent(0.8)
    
}

// MARK: - Toast Manager

/**
 `GL_ToastManager` provides general configuration options for all toast
 notifications. Backed by a singleton instance.
*/
public class GL_ToastManager {
    
    /**
     The `GL_ToastManager` singleton instance.
     
     */
    public static let shared = GL_ToastManager()
    
    /**
     The shared style. Used whenever toastViewForMessage(message:title:image:style:) is called
     with with a nil style.
     
     */
    public var style = GL_ToastStyle()
    
    /**
     Enables or disables tap to dismiss on toast views. Default is `true`.
     
     */
    public var isTapToDismissEnabled = true
    
    /**
     Enables or disables queueing behavior for toast views. When `true`,
     toast views will appear one after the other. When `false`, multiple toast
     views will appear at the same time (potentially overlapping depending
     on their positions). This has no effect on the toast activity view,
     which operates independently of normal toast views. Default is `false`.
     
     */
    public var isQueueEnabled = false
    
    /**
     The default duration. Used for the `makeToast` and
     `showToast` methods that don't require an explicit duration.
     Default is 3.0.
     
     */
    public var duration: TimeInterval = 2.0
    
    /**
     Sets the default position. Used for the `makeToast` and
     `showToast` methods that don't require an explicit position.
     Default is `ToastPosition.Bottom`.
     
     */
    public var position: ToastPosition = .center
    
}

// MARK: - ToastPosition

public enum ToastPosition {
    case top
    case center
    case bottom
    
    fileprivate func centerPoint(forToast toast: UIView, inSuperview superview: UIView) -> CGPoint {
        let topPadding: CGFloat = GL_ToastManager.shared.style.verticalPadding + superview.csSafeAreaInsets.top
        let bottomPadding: CGFloat = GL_ToastManager.shared.style.verticalPadding + superview.csSafeAreaInsets.bottom
        
        switch self {
        case .top:
            return CGPoint(x: superview.bounds.size.width / 2.0, y: (toast.frame.size.height / 2.0) + topPadding)
        case .center:
            return CGPoint(x: superview.bounds.size.width / 2.0, y: superview.bounds.size.height / 2.0)
        case .bottom:
            return CGPoint(x: superview.bounds.size.width / 2.0, y: (superview.bounds.size.height - (toast.frame.size.height / 2.0)) - bottomPadding)
        }
    }
}

// MARK: - Private UIView Extensions

private extension UIView {
    
    var csSafeAreaInsets: UIEdgeInsets {
        if #available(iOS 11.0, *) {
            return self.safeAreaInsets
        } else {
            return .zero
        }
    }
    
}
