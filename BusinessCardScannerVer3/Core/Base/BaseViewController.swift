//
//  BaseViewController.swift
//  BusinessCardScanner
//
//  基礎 ViewController，提供所有 ViewController 共用功能
//

import UIKit

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
    
    // MARK: - Error Handling
    
    /// 顯示錯誤訊息（使用 AlertPresenter）
    /// - Parameters:
    ///   - title: 錯誤標題
    ///   - message: 錯誤訊息
    ///   - completion: 完成回調
    func showError(title: String = "錯誤", message: String, completion: (() -> Void)? = nil) {
        AlertPresenter.shared.showError(
            title: title,
            message: message,
            from: self,
            completion: completion
        )
    }
    
    /// 顯示錯誤物件
    /// - Parameters:
    ///   - error: 錯誤物件
    ///   - completion: 完成回調
    func showError(_ error: Error, completion: (() -> Void)? = nil) {
        AlertPresenter.shared.showError(error, from: self, completion: completion)
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
