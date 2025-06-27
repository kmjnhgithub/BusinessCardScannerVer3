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
    
    private let viewModel = ComponentShowcaseViewModel()
    
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
        
        // 測試 ServiceContainer
        testServiceContainer()
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
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.showLoading("測試載入中...")
                } else {
                    self?.hideLoading()
                }
            }
            .store(in: &cancellables)
        
        viewModel.$testResult
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.showMessage(result, title: "測試結果")
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
            onTap: { [weak self] in
                self?.showMessage("卡片被點擊了")
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
        emptyStateView.actionHandler = { [weak self] in
            self?.showMessage("空狀態按鈕被點擊")
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
        
        let separator1 = SeparatorView.fullWidth()
        contentStack.addArrangedSubview(separator1)
        
        let label2 = UILabel()
        label2.text = "列表樣式分隔線（左側縮排）"
        label2.font = AppTheme.Fonts.body
        contentStack.addArrangedSubview(label2)
        
        let separator2 = SeparatorView.listSeparator()
        contentStack.addArrangedSubview(separator2)
        
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
            .sink { [weak self] result in
                self?.showMessage("Combine 測試結果: \(result)")
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
        showMessage("\(title) 被點擊了")
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
            showMessage("表單驗證通過", title: "成功")
        } else {
            showMessage(errors.joined(separator: "\n"), title: "驗證失敗")
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

// MARK: - ViewModel

/// 元件展示頁面的 ViewModel
class ComponentShowcaseViewModel: BaseViewModel {
    
    // MARK: - Published Properties
    
    @Published var testResult: String?
    @Published var cards: [BusinessCard] = []
    
    // MARK: - Dependencies
    
    private let repository = ServiceContainer.shared.businessCardRepository
    
    // MARK: - Methods
    
    func updateFormData(name: String) {
        print("表單資料更新 - 姓名: \(name)")
    }
    
    func performCombineTest() -> AnyPublisher<String, Never> {
        // 模擬非同步操作
        return Future<String, Never> { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                promise(.success("Combine 測試成功完成"))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func createTestCard() {
        let card = BusinessCard()
        var mutableCard = card
        mutableCard.name = "測試名片 \(Date().timeIntervalSince1970)"
        mutableCard.company = "測試公司"
        mutableCard.email = "test@example.com"
        
        performPublisherOperation(
            publisher: repository.create(mutableCard),
            onSuccess: { [weak self] card in
                self?.testResult = "名片建立成功: \(card.name)"
            },
            onError: { [weak self] error in
                self?.testResult = "建立失敗: \(error.localizedDescription)"
            }
        )
    }
    
    func fetchAllCards() {
        performPublisherOperation(
            publisher: repository.fetchAll(),
            onSuccess: { [weak self] cards in
                self?.cards = cards
                self?.testResult = "載入成功: \(cards.count) 張名片"
            },
            onError: { [weak self] error in
                self?.testResult = "載入失敗: \(error.localizedDescription)"
            }
        )
    }
}
