//
//  BaseViewController.swift
//  
//
//  Base class for all ViewControllers in the app
//

import UIKit
import Combine
import SnapKit

/// 所有 ViewController 的基礎類別
class BaseViewController: UIViewController {
    
    // MARK: - Properties
    
    /// Combine 訂閱集合，會在 deinit 時自動取消
    var cancellables = Set<AnyCancellable>()
    
    /// 是否在 viewDidLoad 時自動隱藏導航列
    var shouldHideNavigationBar: Bool { false }
    
    /// 是否支援大標題
    var prefersLargeTitles: Bool { false }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 設定基本樣式（遵循 UI 設計規範文檔 v1.0）
        view.backgroundColor = AppTheme.Colors.background
        
        // 設定導航列
        configureNavigationBar()
        
        // 子類別實作點
        setupUI()
        setupConstraints()
        setupBindings()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if shouldHideNavigationBar {
            navigationController?.setNavigationBarHidden(true, animated: animated)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if shouldHideNavigationBar {
            navigationController?.setNavigationBarHidden(false, animated: animated)
        }
    }
    
    deinit {
        // cancellables 會自動清理，但明確記錄 deinit 有助於除錯
        #if DEBUG
        print("✅ \(String(describing: type(of: self))) deinit")
        #endif
    }
    
    // MARK: - Setup Methods (子類別覆寫)
    
    /// 設定 UI 元件
    func setupUI() {
        // 子類別覆寫此方法來建立和設定 UI 元件
    }
    
    /// 設定 Auto Layout 約束
    func setupConstraints() {
        // 子類別覆寫此方法來設定 SnapKit 約束
    }
    
    /// 設定 Combine 綁定
    func setupBindings() {
        // 子類別覆寫此方法來設定資料綁定
    }
    
    // MARK: - Configuration
    
    private func configureNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = prefersLargeTitles
        navigationItem.largeTitleDisplayMode = prefersLargeTitles ? .always : .never
    }
    
    // MARK: - Common UI Helpers
    
    /// 顯示載入指示器
    func showLoading(_ message: String? = nil) {
        LoadingPresenter.shared.show(message: message)
    }
    
    /// 隱藏載入指示器
    func hideLoading() {
        LoadingPresenter.shared.hide()
    }
    
    /// 顯示錯誤訊息
    func showError(_ error: Error) {
        // 這裡會在實作 AlertPresenter 後更新
        // 暫時使用系統 alert
        let alert = UIAlertController(
            title: "錯誤",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "確定", style: .default))
        present(alert, animated: true)
    }
    
    /// 顯示提示訊息
    func showMessage(_ message: String, title: String? = nil) {
        // 這裡會在實作 AlertPresenter 後更新
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "確定", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Keyboard Handling
    
    /// 當前鍵盤高度
    private(set) var keyboardHeight: CGFloat = 0
    
    /// 註冊鍵盤事件監聽（遵循 UI 設計規範 v1.0）
    func registerKeyboardObservers() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { notification -> (CGFloat, Double)? in
                guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
                      let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
                    return nil
                }
                return (keyboardFrame.height, duration)
            }
            .sink { [weak self] height, duration in
                self?.keyboardHeight = height
                self?.keyboardWillShow(height: height, duration: duration)
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .compactMap { notification -> Double? in
                notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
            }
            .sink { [weak self] duration in
                self?.keyboardHeight = 0
                self?.keyboardWillHide(duration: duration)
            }
            .store(in: &cancellables)
    }
    
    /// 鍵盤將顯示（子類別可覆寫）
    /// - Parameters:
    ///   - height: 鍵盤高度
    ///   - duration: 動畫時長（遵循系統時長）
    @objc func keyboardWillShow(height: CGFloat, duration: Double) {
        // 子類別覆寫以處理鍵盤顯示
    }
    
    /// 鍵盤將隱藏（子類別可覆寫）
    /// - Parameter duration: 動畫時長（遵循系統時長）
    @objc func keyboardWillHide(duration: Double) {
        // 子類別覆寫以處理鍵盤隱藏
    }
    
    /// 點擊背景收起鍵盤
    func setupDismissKeyboardGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}

// MARK: - Navigation Helpers

extension BaseViewController {
    
    /// 返回上一頁
    func popViewController(animated: Bool = true) {
        navigationController?.popViewController(animated: animated)
    }
    
    /// 返回根視圖
    func popToRootViewController(animated: Bool = true) {
        navigationController?.popToRootViewController(animated: animated)
    }
    
    /// 關閉 Modal
    func dismissViewController(animated: Bool = true, completion: (() -> Void)? = nil) {
        dismiss(animated: animated, completion: completion)
    }
}
