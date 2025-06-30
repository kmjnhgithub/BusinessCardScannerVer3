//
//  ComponentShowcaseViewController.swift
//  BusinessCardScanner
//
//  UI 元件展示測試頁面
//  用於驗證 Task 1.1 - 1.6 的整合效果
//

import UIKit
import SnapKit
import Combine

/// UI 元件展示視圖控制器
/// 整合測試所有基礎架構和 UI 元件
class ComponentShowcaseViewController: BaseViewController {
    
    // MARK: - Properties
    
    private let viewModel: ComponentShowcaseViewModel
    weak var coordinator: ComponentShowcaseCoordinatorProtocol?
    
    // MARK: - Initialization
    
    init(viewModel: ComponentShowcaseViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Components
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()
    
    // 測試元件
    private var testButtons: [ThemedButton] = []
    private var testTextField: ThemedTextField!
    private var testFormFields: [FormFieldView] = []
    private var testCard: CardView!
    private var emptyStateView: EmptyStateView!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "元件展示"
        setupNavigationBar()
        
        // 測試 ServiceContainer
        testServiceContainer()
    }
    
    private func setupNavigationBar() {
        // 添加測試按鈕
        let testButton = UIBarButtonItem(
            title: "執行測試",
            style: .plain,
            target: self,
            action: #selector(runCompleteTest)
        )
        navigationItem.rightBarButtonItem = testButton
    }
    
    @objc private func runCompleteTest() {
        ToastPresenter.shared.showInfo("開始執行完整測試...")
        
        viewModel.runCompleteTest()
            .sink { result in
                ToastPresenter.shared.showSuccess(result)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Setup
    
    override func setupUI() {
        super.setupUI()
        
        // 設定 ScrollView
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.showsVerticalScrollIndicator = true
        scrollView.alwaysBounceVertical = true
        
        // 設定主要 StackView
        stackView.axis = .vertical
        stackView.spacing = AppTheme.Layout.sectionPadding
        stackView.distribution = .fill
        stackView.alignment = .fill
        contentView.addSubview(stackView)
        
        // 建立測試區塊
        setupButtonSection()
        setupTextFieldSection()
        setupFormSection()
        setupCardSection()
        setupEmptyStateSection()
        setupSeparatorSection()
        setupPresenterSection()
        setupCombineTestSection()
        setupRepositoryTestSection()
    }
    
    override func setupConstraints() {
        scrollView.snp_fillSuperview()
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(AppTheme.Layout.screenHorizontalPadding)
        }
    }
    
    override func setupBindings() {
        // 綁定 ViewModel 狀態
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { isLoading in
                if isLoading {
                    LoadingPresenter.shared.show(message: "測試載入中...")
                } else {
                    LoadingPresenter.shared.hide()
                }
            }
            .store(in: &cancellables)
        
        viewModel.$testResult
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { result in
                ToastPresenter.shared.showSuccess(result)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Test Sections
    
    /// 測試按鈕區塊
    private func setupButtonSection() {
        let sectionTitle = createSectionTitle("按鈕樣式測試")
        stackView.addArrangedSubview(sectionTitle)
        
        // 建立不同樣式的按鈕
        let styles: [(ThemedButton.Style, String)] = [
            (.primary, "主要按鈕"),
            (.secondary, "次要按鈕"),
            (.text, "文字按鈕"),
            (.danger, "危險操作")
        ]
        
        let buttonStack = UIStackView()
        buttonStack.axis = .vertical
        buttonStack.spacing = AppTheme.Layout.standardPadding
        
        for (style, title) in styles {
            let button = ThemedButton(style: style)
            button.setTitle(title, for: .normal)
            buttonStack.addArrangedSubview(button)
            testButtons.append(button)
            
            // 測試點擊事件
            button.tapPublisher
                .sink { [weak self] in
                    self?.handleButtonTap(title: title)
                }
                .store(in: &cancellables)
        }
        
        // 載入狀態測試按鈕
        let loadingButton = ThemedButton(style: .primary)
        loadingButton.setTitle("測試載入狀態", for: .normal)
        buttonStack.addArrangedSubview(loadingButton)
        
        loadingButton.tapPublisher
            .sink { [weak loadingButton] in
                loadingButton?.isLoading = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    loadingButton?.isLoading = false
                }
            }
            .store(in: &cancellables)
        
        let card = CardView()
        card.setContent(buttonStack)
        stackView.addArrangedSubview(card)
    }
    
    /// 測試輸入框區塊
    private func setupTextFieldSection() {
        let sectionTitle = createSectionTitle("輸入框測試")
        stackView.addArrangedSubview(sectionTitle)
        
        let card = CardView()
        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = AppTheme.Layout.standardPadding
        
        // 基本輸入框
        testTextField = ThemedTextField()
        testTextField.placeholder = "請輸入測試文字"
        contentStack.addArrangedSubview(testTextField)
        
        // 錯誤狀態測試
        let errorButton = ThemedButton(style: .danger)
        errorButton.setTitle("觸發錯誤狀態", for: .normal)
        contentStack.addArrangedSubview(errorButton)
        
        errorButton.tapPublisher
            .sink { [weak self] in
                self?.testTextField.errorMessage = "這是一個錯誤訊息範例"
            }
            .store(in: &cancellables)
        
        // 文字變更監聽
        testTextField.textPublisher
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] text in
                print("輸入文字變更: \(text)")
                if text.count > 10 {
                    self?.testTextField.errorMessage = "文字太長了"
                }
            }
            .store(in: &cancellables)
        
        card.setContent(contentStack)
        stackView.addArrangedSubview(card)
    }
    
    /// 測試表單區塊
    private func setupFormSection() {
        let sectionTitle = createSectionTitle("表單元件測試")
        stackView.addArrangedSubview(sectionTitle)
        
        // 使用 FormSectionView
        let formSection = FormSectionView.builder()
            .title("基本資訊")
            .backgroundStyle(.card)
            .build()
        
        // 添加表單欄位
        let nameField = FormFieldView.makeName(required: true)
        let emailField = FormFieldView.makeEmail(required: false)
        let phoneField = FormFieldView.makePhone(required: false)
        
        formSection.addFields([nameField, emailField, phoneField])
        
        // 保存參考用於測試
        testFormFields = [nameField, emailField, phoneField]
        
        // 監聽表單變化
        nameField.textPublisher
            .sink { [weak self] text in
                self?.viewModel.updateFormData(name: text)
            }
            .store(in: &cancellables)
        
        emailField.textPublisher
            .sink { [weak self] text in
                self?.viewModel.updateFormData(email: text)
            }
            .store(in: &cancellables)
        
        phoneField.textPublisher
            .sink { [weak self] text in
                self?.viewModel.updateFormData(phone: text)
            }
            .store(in: &cancellables)
        
        stackView.addArrangedSubview(formSection)
        
        // 驗證按鈕
        let validateButton = ThemedButton(style: .primary)
        validateButton.setTitle("驗證表單", for: .normal)
        stackView.addArrangedSubview(validateButton)
        
        validateButton.tapPublisher
            .sink { [weak self] in
                self?.validateForm()
            }
            .store(in: &cancellables)
    }
    
    /// 測試卡片區塊
    private func setupCardSection() {
        let sectionTitle = createSectionTitle("卡片容器測試")
        stackView.addArrangedSubview(sectionTitle)
        
        // 可點擊卡片
        let clickableCard = CardView.makeClickable(
            content: createCardContent(),
            onTap: {
                ToastPresenter.shared.showInfo("卡片被點擊了")
            }
        )
        
        stackView.addArrangedSubview(clickableCard)
        
        // 帶標題的卡片
        let titledCard = CardView.makeWithTitle(
            "測試卡片標題",
            content: createCardContent()
        )
        
        stackView.addArrangedSubview(titledCard)
    }
    
    /// 測試空狀態區塊
    private func setupEmptyStateSection() {
        let sectionTitle = createSectionTitle("空狀態測試")
        stackView.addArrangedSubview(sectionTitle)
        
        emptyStateView = EmptyStateView.makeNoDataState(actionTitle: "新增資料")
        emptyStateView.actionHandler = {
            ToastPresenter.shared.showInfo("空狀態按鈕被點擊")
        }
        
        emptyStateView.snp.makeConstraints { make in
            make.height.equalTo(200)
        }
        
        let card = CardView()
        card.setContent(emptyStateView)
        stackView.addArrangedSubview(card)
    }
    
    /// 測試分隔線區塊
    private func setupSeparatorSection() {
        let sectionTitle = createSectionTitle("分隔線測試")
        stackView.addArrangedSubview(sectionTitle)
        
        let card = CardView()
        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = AppTheme.Layout.standardPadding
        
        // 測試不同樣式的分隔線
        let label1 = UILabel()
        label1.text = "標準分隔線"
        label1.font = AppTheme.Fonts.body
        contentStack.addArrangedSubview(label1)

        // 直接使用，它會自動填滿
        contentStack.addArrangedSubview(SeparatorView.fullWidth())

        let label2 = UILabel()
        label2.text = "列表樣式分隔線（左側縮排）"
        label2.font = AppTheme.Fonts.body
        contentStack.addArrangedSubview(label2)

        // 直接使用，它會自動處理縮排
        contentStack.addArrangedSubview(SeparatorView.listSeparator())
        
        let label3 = UILabel()
        label3.text = "自定義顏色和厚度"
        label3.font = AppTheme.Fonts.body
        contentStack.addArrangedSubview(label3)
        
        let separator3 = SeparatorView.horizontal(thickness: 2)
        separator3.backgroundColor = AppTheme.Colors.primary
        contentStack.addArrangedSubview(separator3)
        
        // 測試垂直分隔線
        let horizontalStack = UIStackView()
        horizontalStack.axis = .horizontal
        horizontalStack.spacing = AppTheme.Layout.standardPadding
        // 將 .fillEqually 改為 .fill
        horizontalStack.distribution = .fill

        
        let leftLabel = UILabel()
        leftLabel.text = "左側"
        leftLabel.textAlignment = .center
        
        let verticalSeparator = SeparatorView.vertical()
        
        let rightLabel = UILabel()
        rightLabel.text = "右側"
        rightLabel.textAlignment = .center
        
        horizontalStack.addArrangedSubviews(leftLabel, verticalSeparator, rightLabel)
        // 關鍵：由於 SeparatorView 有固定的寬度，我們需要告訴 StackView
        // 另外兩個 Label 應該如何填充空間。我們可以讓它們的寬度相等。
        leftLabel.snp.makeConstraints { make in
            make.width.equalTo(rightLabel.snp.width)
        }

        contentStack.addArrangedSubview(horizontalStack)
        
        card.setContent(contentStack)
        stackView.addArrangedSubview(card)
    }
    
    /// 測試 UI Presenter 元件
    private func setupPresenterSection() {
        let sectionTitle = createSectionTitle("UI Presenter 測試")
        stackView.addArrangedSubview(sectionTitle)
        
        let card = CardView()
        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = AppTheme.Layout.standardPadding
        
        // AlertPresenter 測試
        let alertSection = createSubsectionTitle("AlertPresenter")
        contentStack.addArrangedSubview(alertSection)
        
        let alertButtons = createAlertTestButtons()
        contentStack.addArrangedSubview(alertButtons)
        
        // LoadingPresenter 測試
        let loadingSection = createSubsectionTitle("LoadingPresenter")
        contentStack.addArrangedSubview(loadingSection)
        
        let loadingButtons = createLoadingTestButtons()
        contentStack.addArrangedSubview(loadingButtons)
        
        // ToastPresenter 測試
        let toastSection = createSubsectionTitle("ToastPresenter")
        contentStack.addArrangedSubview(toastSection)
        
        let toastButtons = createToastTestButtons()
        contentStack.addArrangedSubview(toastButtons)
        
        card.setContent(contentStack)
        stackView.addArrangedSubview(card)
    }
    
    /// 測試 Combine 整合
    private func setupCombineTestSection() {
        let sectionTitle = createSectionTitle("Combine 整合測試")
        stackView.addArrangedSubview(sectionTitle)
        
        let card = CardView()
        let testButton = ThemedButton(style: .secondary)
        testButton.setTitle("測試 Combine 資料流", for: .normal)
        
        testButton.tapPublisher
            .flatMap { [weak self] _ -> AnyPublisher<String, Never> in
                guard let self = self else {
                    return Just("錯誤").eraseToAnyPublisher()
                }
                return self.viewModel.performCombineTest()
            }
            .sink { result in
                ToastPresenter.shared.showSuccess("Combine 測試結果: \(result)")
            }
            .store(in: &cancellables)
        
        card.setContent(testButton)
        stackView.addArrangedSubview(card)
    }
    
    /// 測試 Repository 整合
    private func setupRepositoryTestSection() {
        let sectionTitle = createSectionTitle("Repository 測試")
        stackView.addArrangedSubview(sectionTitle)
        
        let card = CardView()
        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = AppTheme.Layout.standardPadding
        
        // 測試按鈕
        let createButton = ThemedButton(style: .primary)
        createButton.setTitle("建立測試名片", for: .normal)
        
        let fetchButton = ThemedButton(style: .secondary)
        fetchButton.setTitle("載入所有名片", for: .normal)
        
        contentStack.addArrangedSubviews(createButton, fetchButton)
        
        // 綁定事件
        createButton.tapPublisher
            .sink { [weak self] in
                self?.viewModel.createTestCard()
            }
            .store(in: &cancellables)
        
        fetchButton.tapPublisher
            .sink { [weak self] in
                self?.viewModel.fetchAllCards()
            }
            .store(in: &cancellables)
        
        card.setContent(contentStack)
        stackView.addArrangedSubview(card)
    }
    
    // MARK: - Helper Methods
    
    private func createSectionTitle(_ title: String) -> UILabel {
        let label = UILabel()
        label.text = title.uppercased()
        label.font = AppTheme.Fonts.footnote
        label.textColor = AppTheme.Colors.secondaryText
        return label
    }
    
    private func createCardContent() -> UIView {
        let contentView = UIView()
        let label = UILabel()
        label.text = "這是卡片內容"
        label.font = AppTheme.Fonts.body
        label.textColor = AppTheme.Colors.primaryText
        label.numberOfLines = 0
        
        contentView.addSubview(label)
        label.snp_fillSuperview(padding: AppTheme.Layout.standardPadding)
        
        return contentView
    }
    
    private func handleButtonTap(title: String) {
        print("按鈕點擊: \(title)")
        ToastPresenter.shared.showInfo("\(title) 被點擊了")
    }
    
    private func createSubsectionTitle(_ title: String) -> UILabel {
        let label = UILabel()
        label.text = title
        label.font = AppTheme.Fonts.body
        label.textColor = AppTheme.Colors.primaryText
        return label
    }
    
    private func createAlertTestButtons() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = AppTheme.Layout.compactPadding
        
        let infoButton = ThemedButton(style: .secondary)
        infoButton.setTitle("資訊提示", for: .normal)
        infoButton.tapPublisher
            .sink {
                AlertPresenter.shared.showMessage("這是一個資訊提示訊息", title: "資訊")
            }
            .store(in: &cancellables)
        
        let warningButton = ThemedButton(style: .secondary)
        warningButton.setTitle("警告提示", for: .normal)
        warningButton.tapPublisher
            .sink {
                AlertPresenter.shared.showMessage("這是一個警告訊息", title: "警告")
            }
            .store(in: &cancellables)
        
        let errorButton = ThemedButton(style: .danger)
        errorButton.setTitle("錯誤提示", for: .normal)
        errorButton.tapPublisher
            .sink {
                AlertPresenter.shared.showMessage("這是一個錯誤訊息", title: "錯誤")
            }
            .store(in: &cancellables)
        
        let confirmButton = ThemedButton(style: .primary)
        confirmButton.setTitle("確認對話框", for: .normal)
        confirmButton.tapPublisher
            .sink {
                AlertPresenter.shared.showConfirmation(
                    "確定要執行這個操作嗎？",
                    title: "確認",
                    onConfirm: {
                        ToastPresenter.shared.showSuccess("操作已確認")
                    },
                    onCancel: {
                        ToastPresenter.shared.showInfo("操作已取消")
                    }
                )
            }
            .store(in: &cancellables)
        
        let menuButton = ThemedButton(style: .text)
        menuButton.setTitle("選項選單", for: .normal)
        menuButton.tapPublisher
            .sink { [weak self] in
                self?.showMenuTest()
            }
            .store(in: &cancellables)
        
        stackView.addArrangedSubviews(infoButton, warningButton, errorButton, confirmButton, menuButton)
        return stackView
    }
    
    private func createLoadingTestButtons() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = AppTheme.Layout.compactPadding
        
        let simpleLoadingButton = ThemedButton(style: .secondary)
        simpleLoadingButton.setTitle("簡單載入", for: .normal)
        simpleLoadingButton.tapPublisher
            .sink {
                LoadingPresenter.shared.show()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    LoadingPresenter.shared.hide()
                    ToastPresenter.shared.showSuccess("載入完成")
                }
            }
            .store(in: &cancellables)
        
        let messageLoadingButton = ThemedButton(style: .secondary)
        messageLoadingButton.setTitle("帶訊息載入", for: .normal)
        messageLoadingButton.tapPublisher
            .sink {
                LoadingPresenter.shared.show(message: "正在處理資料...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    LoadingPresenter.shared.hide()
                    ToastPresenter.shared.showSuccess("資料處理完成")
                }
            }
            .store(in: &cancellables)
        
        let progressLoadingButton = ThemedButton(style: .secondary)
        progressLoadingButton.setTitle("進度載入", for: .normal)
        progressLoadingButton.tapPublisher
            .sink { [weak self] in
                self?.showProgressLoading()
            }
            .store(in: &cancellables)
        
        stackView.addArrangedSubviews(simpleLoadingButton, messageLoadingButton, progressLoadingButton)
        return stackView
    }
    
    private func createToastTestButtons() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = AppTheme.Layout.compactPadding
        
        let successButton = ThemedButton(style: .primary)
        successButton.setTitle("成功提示", for: .normal)
        successButton.tapPublisher
            .sink {
                ToastPresenter.shared.showSuccess("操作成功完成")
            }
            .store(in: &cancellables)
        
        let infoButton = ThemedButton(style: .secondary)
        infoButton.setTitle("資訊提示", for: .normal)
        infoButton.tapPublisher
            .sink {
                ToastPresenter.shared.showInfo("這是一個資訊提示")
            }
            .store(in: &cancellables)
        
        let warningButton = ThemedButton(style: .secondary)
        warningButton.setTitle("警告提示", for: .normal)
        warningButton.tapPublisher
            .sink {
                ToastPresenter.shared.showWarning("這是一個警告提示")
            }
            .store(in: &cancellables)
        
        let errorButton = ThemedButton(style: .danger)
        errorButton.setTitle("錯誤提示", for: .normal)
        errorButton.tapPublisher
            .sink {
                ToastPresenter.shared.showError("這是一個錯誤提示")
            }
            .store(in: &cancellables)
        
        let customButton = ThemedButton(style: .text)
        customButton.setTitle("自訂提示", for: .normal)
        customButton.tapPublisher
            .sink {
                ToastPresenter.shared.show("自訂內容的提示訊息", duration: 3.0)
            }
            .store(in: &cancellables)
        
        stackView.addArrangedSubviews(successButton, infoButton, warningButton, errorButton, customButton)
        return stackView
    }
    
    private func showMenuTest() {
        let options = ["選項一", "選項二", "選項三"]
        let actions = options.map { option in
            AlertPresenter.AlertAction.default(option) {
                ToastPresenter.shared.showInfo("已選擇：\(option)")
            }
        }
        
        AlertPresenter.shared.showActionSheet(
            title: "請選擇一個選項",
            actions: actions
        )
    }
    
    private func showProgressLoading() {
        LoadingPresenter.shared.show(message: "載入進度中...")
        
        var progress: Float = 0.0
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            progress += 0.1
            LoadingPresenter.shared.updateProgress(progress)
            
            if progress >= 1.0 {
                timer.invalidate()
                LoadingPresenter.shared.hide()
                ToastPresenter.shared.showSuccess("進度載入完成")
            }
        }
    }
    
    private func validateForm() {
        var isValid = true
        var errors: [String] = []
        
        for field in testFormFields {
            if !field.validate() {
                isValid = false
                if let title = field.title {
                    errors.append("\(title) 驗證失敗")
                }
            }
        }
        
        if isValid {
            ToastPresenter.shared.showSuccess("表單驗證通過")
        } else {
            AlertPresenter.shared.showMessage(errors.joined(separator: "\n"), title: "驗證失敗")
        }
    }
    
    private func testServiceContainer() {
        // 測試 ServiceContainer 是否正常運作
        let container = ServiceContainer.shared
        let repository = container.businessCardRepository
        
        print("ServiceContainer 測試:")
        print("- Repository 建立成功: \(repository)")
        print("- CoreDataStack 狀態: \(container.coreDataStack)")
        
        #if DEBUG
        container.coreDataStack.printStatistics()
        #endif
    }
}

