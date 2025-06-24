//
//  TestUIComponentsViewController.swift
//  BusinessCardScanner
//
//  測試基礎 UI 元件
//

import UIKit

class TestUIComponentsViewController: BaseViewController {
    
    // MARK: - UI Elements
    
    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // MARK: - Setup
    
    override func setupUI() {
        super.setupUI()
        
        title = "UI 元件測試"
        view.backgroundColor = .systemBackground
        
        view.addSubview(stackView)
        
        // 建立測試按鈕
        let buttons = [
            createButton(title: "測試 Alert", action: #selector(testAlert)),
            createButton(title: "測試 Confirmation", action: #selector(testConfirmation)),
            createButton(title: "測試 Delete Alert", action: #selector(testDeleteAlert)),
            createButton(title: "測試 Action Sheet", action: #selector(testActionSheet)),
            createButton(title: "測試 Text Input", action: #selector(testTextInput)),
            createButton(title: "測試 Loading", action: #selector(testLoading)),
            createButton(title: "測試 Success Toast", action: #selector(testSuccessToast)),
            createButton(title: "測試 Error Toast", action: #selector(testErrorToast)),
            createButton(title: "測試 Warning Toast", action: #selector(testWarningToast)),
            createButton(title: "測試 Info Toast", action: #selector(testInfoToast))
        ]
        
        buttons.forEach { stackView.addArrangedSubview($0) }
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - Helper Methods
    
    private func createButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
    
    // MARK: - Test Actions
    
    @objc private func testAlert() {
        AlertPresenter.shared.showAlert(
            title: "測試 Alert",
            message: "這是一個基本的 Alert 測試",
            actions: [
                AlertAction(title: "選項 1") {
                    self.showSuccessToast("選擇了選項 1")
                },
                AlertAction(title: "選項 2") {
                    self.showSuccessToast("選擇了選項 2")
                }
            ],
            from: self
        )
    }
    
    @objc private func testConfirmation() {
        AlertPresenter.shared.showConfirmation(
            title: "確認操作",
            message: "您確定要執行這個操作嗎？",
            confirmHandler: {
                self.showSuccessToast("已確認")
            },
            from: self
        )
    }
    
    @objc private func testDeleteAlert() {
        AlertPresenter.shared.showDeleteConfirmation(
            itemName: "測試名片",
            deleteHandler: {
                self.showSuccessToast("已刪除")
            },
            from: self
        )
    }
    
    @objc private func testActionSheet() {
        AlertPresenter.shared.showActionSheet(
            title: "選擇操作",
            message: "請選擇要執行的操作",
            actions: [
                AlertAction(title: "拍照", style: .default) {
                    self.showInfoToast("選擇了拍照")
                },
                AlertAction(title: "從相簿選擇", style: .default) {
                    self.showInfoToast("選擇了相簿")
                },
                AlertAction(title: "刪除", style: .destructive) {
                    self.showErrorToast("選擇了刪除")
                }
            ],
            sourceView: self.view,
            from: self
        )
    }
    
    @objc private func testTextInput() {
        AlertPresenter.shared.showTextInput(
            title: "輸入名稱",
            message: "請輸入新的名片名稱",
            placeholder: "名稱",
            defaultValue: "預設名稱",
            confirmHandler: { text in
                if let text = text, !text.isEmpty {
                    self.showSuccessToast("輸入：\(text)")
                } else {
                    self.showErrorToast("未輸入任何內容")
                }
            },
            from: self
        )
    }
    
    @objc private func testLoading() {
        showLoading(message: "載入中...")
        
        // 2 秒後更新訊息
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.updateLoadingMessage("即將完成...")
            
            // 再 1 秒後隱藏
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.hideLoading()
                self.showSuccessToast("載入完成")
            }
        }
    }
    
    @objc private func testSuccessToast() {
        showSuccessToast("操作成功！")
    }
    
    @objc private func testErrorToast() {
        showErrorToast("發生錯誤")
    }
    
    @objc private func testWarningToast() {
        showWarningToast("請注意！")
    }
    
    @objc private func testInfoToast() {
        showInfoToast("這是一則資訊")
    }
}
