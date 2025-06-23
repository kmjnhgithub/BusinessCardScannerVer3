//
//  BaseViewController.swift
//  BusinessCardScanner
//
//  基礎 ViewController，提供所有 ViewController 共用功能
//

import UIKit
import SnapKit

class BaseViewController: UIViewController {
    
    // MARK: - Properties
    
    /// 是否顯示導航列
    var shouldShowNavigationBar: Bool {
        return true
    }
    
    /// 是否隱藏返回按鈕文字
    var shouldHideBackButtonTitle: Bool {
        return true
    }
    
    /// Loading 視圖
    private lazy var loadingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.isHidden = true
        
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = .white
        activityIndicator.startAnimating()
        
        view.addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        return view
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupBindings()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 設定導航列顯示狀態
        navigationController?.setNavigationBarHidden(!shouldShowNavigationBar, animated: animated)
        
        // 設定返回按鈕樣式
        if shouldHideBackButtonTitle {
            navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        }
    }
    
    // MARK: - Setup Methods
    
    /// 設定 UI 元件
    /// 子類別應該覆寫此方法來設定自己的 UI
    func setupUI() {
        view.backgroundColor = .systemBackground
        
        // 添加 loading view
        view.addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    /// 設定 Auto Layout 約束
    /// 子類別應該覆寫此方法來設定自己的約束
    func setupConstraints() {
        // 子類別實作
    }
    
    /// 設定資料綁定
    /// 子類別應該覆寫此方法來設定 ViewModel 綁定
    func setupBindings() {
        // 子類別實作
    }
    
    // MARK: - Loading Management
    
    /// 顯示 Loading
    func showLoading() {
        DispatchQueue.main.async { [weak self] in
            self?.loadingView.isHidden = false
            self?.view.bringSubviewToFront(self?.loadingView ?? UIView())
        }
    }
    
    /// 隱藏 Loading
    func hideLoading() {
        DispatchQueue.main.async { [weak self] in
            self?.loadingView.isHidden = true
        }
    }
    
    // MARK: - Error Handling
    
    /// 顯示錯誤訊息
    /// - Parameters:
    ///   - title: 錯誤標題
    ///   - message: 錯誤訊息
    ///   - completion: 完成回調
    func showError(title: String = "錯誤", message: String, completion: (() -> Void)? = nil) {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "確定", style: .default) { _ in
                completion?()
            })
            self?.present(alert, animated: true)
        }
    }
    
    // MARK: - Keyboard Handling
    
    /// 註冊鍵盤通知
    func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    /// 取消註冊鍵盤通知
    func unregisterKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    /// 鍵盤將顯示
    /// 子類別可覆寫此方法來處理鍵盤顯示
    @objc func keyboardWillShow(_ notification: Notification) {
        // 子類別實作
    }
    
    /// 鍵盤將隱藏
    /// 子類別可覆寫此方法來處理鍵盤隱藏
    @objc func keyboardWillHide(_ notification: Notification) {
        // 子類別實作
    }
    
    // MARK: - Deinit
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        print("\(String(describing: self)) deinit")
    }
}
