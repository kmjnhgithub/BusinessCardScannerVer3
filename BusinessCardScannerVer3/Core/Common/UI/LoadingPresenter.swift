//
//  LoadingPresenter.swift
//  BusinessCardScanner
//
//  統一管理 Loading 狀態顯示
//

import UIKit

/// Loading 顯示器
final class LoadingPresenter {
    
    // MARK: - Singleton
    
    static let shared = LoadingPresenter()
    
    // MARK: - Properties
    
    /// Loading 視圖映射表（使用 NSMapTable 避免循環引用）
    private let loadingViews = NSMapTable<UIViewController, UIView>.weakToStrongObjects()
    
    /// 同步鎖
    private let lock = NSLock()
    
    // MARK: - Private Init
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// 顯示 Loading
    /// - Parameters:
    ///   - message: Loading 訊息（可選）
    ///   - presenter: 顯示的 ViewController
    func show(message: String? = nil, in presenter: UIViewController) {
        lock.lock()
        defer { lock.unlock() }
        
        // 如果已經在顯示，先移除
        if loadingViews.object(forKey: presenter) != nil {
            hide(from: presenter)
        }
        
        DispatchQueue.main.async { [weak self, weak presenter] in
            guard let self = self, let presenter = presenter else { return }
            
            // 建立 Loading 視圖
            let loadingView = self.createLoadingView(message: message)
            
            // 添加到視圖
            presenter.view.addSubview(loadingView)
            loadingView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                loadingView.topAnchor.constraint(equalTo: presenter.view.topAnchor),
                loadingView.leadingAnchor.constraint(equalTo: presenter.view.leadingAnchor),
                loadingView.trailingAnchor.constraint(equalTo: presenter.view.trailingAnchor),
                loadingView.bottomAnchor.constraint(equalTo: presenter.view.bottomAnchor)
            ])
            
            // 儲存參考
            self.lock.lock()
            self.loadingViews.setObject(loadingView, forKey: presenter)
            self.lock.unlock()
            
            // 動畫顯示
            loadingView.alpha = 0
            UIView.animate(withDuration: 0.25) {
                loadingView.alpha = 1
            }
        }
    }
    
    /// 隱藏 Loading
    /// - Parameter presenter: 顯示的 ViewController
    func hide(from presenter: UIViewController) {
        lock.lock()
        let loadingView = loadingViews.object(forKey: presenter)
        loadingViews.removeObject(forKey: presenter)
        lock.unlock()
        
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.25, animations: {
                loadingView?.alpha = 0
            }) { _ in
                loadingView?.removeFromSuperview()
            }
        }
    }
    
    /// 更新 Loading 訊息
    /// - Parameters:
    ///   - message: 新的訊息
    ///   - presenter: 顯示的 ViewController
    func updateMessage(_ message: String, in presenter: UIViewController) {
        lock.lock()
        let loadingView = loadingViews.object(forKey: presenter)
        lock.unlock()
        
        DispatchQueue.main.async {
            if let label = loadingView?.subviews.compactMap({ $0 as? UILabel }).first {
                label.text = message
            }
        }
    }
    
    /// 隱藏所有 Loading
    func hideAll() {
        lock.lock()
        let enumerator = loadingViews.objectEnumerator()
        var allLoadingViews: [UIView] = []
        while let view = enumerator?.nextObject() as? UIView {
            allLoadingViews.append(view)
        }
        loadingViews.removeAllObjects()
        lock.unlock()
        
        DispatchQueue.main.async {
            allLoadingViews.forEach { loadingView in
                UIView.animate(withDuration: 0.25, animations: {
                    loadingView.alpha = 0
                }) { _ in
                    loadingView.removeFromSuperview()
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// 建立 Loading 視圖
    private func createLoadingView(message: String?) -> UIView {
        // 背景視圖
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        // 內容容器
        let contentView = UIView()
        contentView.backgroundColor = UIColor.systemBackground
        contentView.layer.cornerRadius = 12
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOpacity = 0.2
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.layer.shadowRadius = 4
        
        // Activity Indicator
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = .label
        activityIndicator.startAnimating()
        
        // 設定佈局
        backgroundView.addSubview(contentView)
        contentView.addSubview(activityIndicator)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        var constraints = [
            contentView.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor),
            contentView.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor),
            contentView.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120),
            
            activityIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            activityIndicator.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 30)
        ]
        
        // 如果有訊息，添加標籤
        if let message = message {
            let messageLabel = UILabel()
            messageLabel.text = message
            messageLabel.textAlignment = .center
            messageLabel.font = .systemFont(ofSize: 14)
            messageLabel.textColor = .secondaryLabel
            messageLabel.numberOfLines = 0
            
            contentView.addSubview(messageLabel)
            messageLabel.translatesAutoresizingMaskIntoConstraints = false
            
            constraints.append(contentsOf: [
                messageLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 20),
                messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
                messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
                messageLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
            ])
        } else {
            constraints.append(
                activityIndicator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30)
            )
        }
        
        NSLayoutConstraint.activate(constraints)
        
        return backgroundView
    }
}

// MARK: - Convenience Extensions

extension UIViewController {
    
    /// 顯示 Loading
    func showLoading(message: String? = nil) {
        LoadingPresenter.shared.show(message: message, in: self)
    }
    
    /// 隱藏 Loading
    func hideLoading() {
        LoadingPresenter.shared.hide(from: self)
    }
    
    /// 更新 Loading 訊息
    func updateLoadingMessage(_ message: String) {
        LoadingPresenter.shared.updateMessage(message, in: self)
    }
}
