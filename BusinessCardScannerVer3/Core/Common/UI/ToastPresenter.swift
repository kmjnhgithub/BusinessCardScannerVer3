//
//  ToastPresenter.swift
//  BusinessCardScanner
//
//  Toast 訊息顯示
//

import UIKit

/// Toast 位置
enum ToastPosition {
    case top
    case center
    case bottom
}

/// Toast 樣式
enum ToastStyle {
    case info
    case success
    case warning
    case error
    
    var backgroundColor: UIColor {
        switch self {
        case .info:
            return .systemGray
        case .success:
            return .systemGreen
        case .warning:
            return .systemOrange
        case .error:
            return .systemRed
        }
    }
    
    var icon: UIImage? {
        switch self {
        case .info:
            return UIImage(systemName: "info.circle.fill")
        case .success:
            return UIImage(systemName: "checkmark.circle.fill")
        case .warning:
            return UIImage(systemName: "exclamationmark.triangle.fill")
        case .error:
            return UIImage(systemName: "xmark.circle.fill")
        }
    }
}

/// Toast 顯示器
final class ToastPresenter {
    
    // MARK: - Singleton
    
    static let shared = ToastPresenter()
    
    // MARK: - Properties
    
    /// 當前顯示的 Toast
    private var currentToast: UIView?
    
    /// 顯示佇列
    private var toastQueue: [(message: String, style: ToastStyle, duration: TimeInterval)] = []
    
    /// 是否正在顯示
    private var isShowing = false
    
    /// 執行緒鎖
    private let lock = NSLock()
    
    // MARK: - Private Init
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// 顯示 Toast
    /// - Parameters:
    ///   - message: 訊息內容
    ///   - style: Toast 樣式
    ///   - position: 顯示位置
    ///   - duration: 顯示時間（秒）
    ///   - presenter: 顯示的 ViewController（nil 則顯示在最上層）
    func show(
        message: String,
        style: ToastStyle = .info,
        position: ToastPosition = .bottom,
        duration: TimeInterval = 2.0,
        in presenter: UIViewController? = nil
    ) {
        lock.lock()
        // 加入佇列
        toastQueue.append((message, style, duration))
        let shouldShow = !isShowing
        lock.unlock()
        
        // 如果沒有正在顯示，開始顯示
        if shouldShow {
            showNext(position: position, in: presenter)
        }
    }
    
    /// 顯示成功訊息
    func showSuccess(_ message: String, in presenter: UIViewController? = nil) {
        show(message: message, style: .success, in: presenter)
    }
    
    /// 顯示錯誤訊息
    func showError(_ message: String, in presenter: UIViewController? = nil) {
        show(message: message, style: .error, in: presenter)
    }
    
    /// 顯示警告訊息
    func showWarning(_ message: String, in presenter: UIViewController? = nil) {
        show(message: message, style: .warning, in: presenter)
    }
    
    /// 顯示資訊訊息
    func showInfo(_ message: String, in presenter: UIViewController? = nil) {
        show(message: message, style: .info, in: presenter)
    }
    
    /// 隱藏當前 Toast
    func hide() {
        guard let toast = currentToast else { return }
        
        UIView.animate(withDuration: 0.3, animations: {
            toast.alpha = 0
            toast.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            toast.removeFromSuperview()
            self.currentToast = nil
            
            self.lock.lock()
            self.isShowing = false
            let hasMore = !self.toastQueue.isEmpty
            self.lock.unlock()
            
            // 顯示下一個
            if hasMore {
                self.showNext()
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// 顯示下一個 Toast
    private func showNext(position: ToastPosition = .bottom, in presenter: UIViewController? = nil) {
        lock.lock()
        guard !toastQueue.isEmpty else {
            lock.unlock()
            return
        }
        
        isShowing = true
        let (message, style, duration) = toastQueue.removeFirst()
        lock.unlock()
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 決定顯示的視圖
            let targetView: UIView
            if let presenter = presenter {
                targetView = presenter.view
            } else if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
                targetView = window
            } else {
                return
            }
            
            // 建立 Toast
            let toast = self.createToast(message: message, style: style)
            self.currentToast = toast
            
            // 添加到視圖
            targetView.addSubview(toast)
            
            // 設定約束
            toast.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                toast.centerXAnchor.constraint(equalTo: targetView.centerXAnchor),
                toast.leadingAnchor.constraint(greaterThanOrEqualTo: targetView.leadingAnchor, constant: 20),
                toast.trailingAnchor.constraint(lessThanOrEqualTo: targetView.trailingAnchor, constant: -20)
            ])
            
            // 根據位置設定約束
            switch position {
            case .top:
                toast.topAnchor.constraint(equalTo: targetView.safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true
            case .center:
                toast.centerYAnchor.constraint(equalTo: targetView.centerYAnchor).isActive = true
            case .bottom:
                toast.bottomAnchor.constraint(equalTo: targetView.safeAreaLayoutGuide.bottomAnchor, constant: -20).isActive = true
            }
            
            // 動畫顯示
            toast.alpha = 0
            toast.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            
            UIView.animate(withDuration: 0.3, animations: {
                toast.alpha = 1
                toast.transform = .identity
            }) { _ in
                // 自動隱藏
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    self.hide()
                }
            }
        }
    }
    
    /// 建立 Toast 視圖
    private func createToast(message: String, style: ToastStyle) -> UIView {
        // 容器視圖
        let containerView = UIView()
        containerView.backgroundColor = style.backgroundColor
        containerView.layer.cornerRadius = 25
        containerView.clipsToBounds = true
        
        // 內容堆疊視圖
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.alignment = .center
        
        // 圖標
        if let icon = style.icon {
            let iconImageView = UIImageView(image: icon)
            iconImageView.tintColor = .white
            iconImageView.contentMode = .scaleAspectFit
            NSLayoutConstraint.activate([
                iconImageView.widthAnchor.constraint(equalToConstant: 24),
                iconImageView.heightAnchor.constraint(equalToConstant: 24)
            ])
            stackView.addArrangedSubview(iconImageView)
        }
        
        // 文字標籤
        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.textColor = .white
        messageLabel.font = .systemFont(ofSize: 14, weight: .medium)
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        stackView.addArrangedSubview(messageLabel)
        
        // 添加到容器
        containerView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 50)
        ])
        
        // 添加陰影
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.2
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 4
        
        return containerView
    }
}

// MARK: - Convenience Extensions

extension UIViewController {
    
    /// 顯示 Toast
    func showToast(_ message: String, style: ToastStyle = .info) {
        ToastPresenter.shared.show(message: message, style: style, in: self)
    }
    
    /// 顯示成功 Toast
    func showSuccessToast(_ message: String) {
        ToastPresenter.shared.showSuccess(message, in: self)
    }
    
    /// 顯示錯誤 Toast
    func showErrorToast(_ message: String) {
        ToastPresenter.shared.showError(message, in: self)
    }
    
    /// 顯示警告 Toast
    func showWarningToast(_ message: String) {
        ToastPresenter.shared.showWarning(message, in: self)
    }
    
    /// 顯示資訊 Toast
    func showInfoToast(_ message: String) {
        ToastPresenter.shared.showInfo(message, in: self)
    }
}
