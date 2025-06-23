//
//  TestViewController.swift
//  BusinessCardScanner
//
//  測試基礎類別的範例 ViewController
//

import UIKit
import SnapKit

// 測試用 ViewModel
class TestViewModel: BaseViewModel {
    let messageText = Observable<String>("Hello MVVM!")
    
    func updateMessage() {
        startLoading()
        
        // 模擬非同步操作
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.messageText.value = "更新成功！時間：\(Date())"
            self?.showSuccess("訊息已更新")
        }
    }
}

// 測試用 ViewController
class TestViewController: BaseViewController {
    
    // MARK: - Properties
    
    private let viewModel = TestViewModel()
    private let disposeBag = DisposeBag()
    
    // MARK: - UI Elements
    
    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 18)
        return label
    }()
    
    private lazy var updateButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("更新訊息", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.addTarget(self, action: #selector(updateButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Setup
    
    override func setupUI() {
        super.setupUI()
        
        title = "測試頁面"
        
        view.addSubview(messageLabel)
        view.addSubview(updateButton)
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        
        messageLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        updateButton.snp.makeConstraints { make in
            make.top.equalTo(messageLabel.snp.bottom).offset(30)
            make.centerX.equalToSuperview()
            make.width.equalTo(120)
            make.height.equalTo(44)
        }
    }
    
    override func setupBindings() {
        super.setupBindings()
        
        // 綁定訊息文字
        viewModel.messageText
            .bind { [weak self] text in
                self?.messageLabel.text = text
            }
            .disposed(by: disposeBag)
        
        // 綁定 Loading 狀態
        viewModel.isLoading
            .bind { [weak self] isLoading in
                if isLoading {
                    self?.showLoading()
                } else {
                    self?.hideLoading()
                }
            }
            .disposed(by: disposeBag)
        
        // 綁定成功訊息
        viewModel.successMessage
            .bind { [weak self] message in
                guard let message = message else { return }
                self?.showError(title: "成功", message: message)
            }
            .disposed(by: disposeBag)
    }
    
    // MARK: - Actions
    
    @objc private func updateButtonTapped() {
        viewModel.updateMessage()
    }
}
