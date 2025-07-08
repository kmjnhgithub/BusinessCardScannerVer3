//
//  CardListViewController.swift
//  BusinessCardScannerVer3
//
//  名片列表視圖控制器
//

import UIKit
import SnapKit
import Combine

// MARK: - CardListCoordinatorDelegate

/// CardList 模組與 Coordinator 的通訊協議
protocol CardListCoordinatorDelegate: AnyObject {
    /// 選中名片時呼叫
    func cardListDidSelectCard(_ card: BusinessCard)
    
    /// 請求新增名片時呼叫
    func cardListDidRequestNewCard()
    
    /// 請求編輯名片時呼叫
    func cardListDidRequestEdit(_ card: BusinessCard)
}

class CardListViewController: BaseViewController {
    
    // MARK: - UI Elements
    
    private let tableView = UITableView()
    private let searchController = UISearchController(searchResultsController: nil)
    private let emptyStateView = EmptyStateView()
    private let addButton = UIButton(type: .system)
    
    // MARK: - Properties
    
    // Note: Made internal for testing purposes
    var viewModel: CardListViewModel!
    
    /// PhotoService 用於載入名片照片
    private var photoService: PhotoServiceProtocol!
    
    /// Coordinator 委託 - 用於處理導航
    weak var coordinatorDelegate: CardListCoordinatorDelegate?
    
    // MARK: - Initialization
    
    init(viewModel: CardListViewModel, photoService: PhotoServiceProtocol) {
        self.viewModel = viewModel
        self.photoService = photoService
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupBindings()
        
        // 載入資料
        viewModel.loadCards()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 遵循 MVVM 原則：View 不主動觸發業務邏輯
        // ViewModel 透過 Combine 和 NotificationCenter 自動管理狀態
        // 如需重新載入，應由 Coordinator 或特定事件觸發
    }
    
    // MARK: - Setup
    
    override func setupUI() {
        super.setupUI()
        
        title = "名片"
        view.backgroundColor = AppTheme.Colors.background
        
        // 設定導航列
        setupNavigationBar()
        
        // 設定搜尋控制器
        setupSearchController()
        
        // 設定表格視圖
        setupTableView()
        
        // 設定空狀態視圖
        setupEmptyStateView()
        
        // 設定新增按鈕
        setupAddButton()
        
        // 添加子視圖
        view.addSubview(tableView)
        view.addSubview(emptyStateView)
        view.addSubview(addButton)
    }
    
    private func setupNavigationBar() {
        // 右側新增按鈕
        let addBarButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonTapped)
        )
        navigationItem.rightBarButtonItem = addBarButton
    }
    
    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "搜尋姓名、公司、電話、Email"
        searchController.searchBar.searchBarStyle = .minimal
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }
    
    private func setupTableView() {
        tableView.backgroundColor = AppTheme.Colors.background
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 100, right: 0) // 底部留空間給浮動按鈕
        
        // 註冊 Cell
        tableView.register(BusinessCardCell.self, forCellReuseIdentifier: BusinessCardCell.reuseIdentifier)
        
        // 設定代理
        tableView.delegate = self
        tableView.dataSource = self
        
        // 下拉刷新
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshControlValueChanged), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    private func setupEmptyStateView() {
        emptyStateView.configure(
            image: UIImage(systemName: "rectangle.stack"),
            title: "還沒有名片",
            message: "點擊 + 新增第一張名片"
        )
        
        emptyStateView.isHidden = true
    }
    
    private func setupAddButton() {
        addButton.backgroundColor = AppTheme.Colors.primary
        addButton.setImage(UIImage(systemName: "plus"), for: .normal)
        addButton.tintColor = .white
        addButton.layer.cornerRadius = 28
        addButton.layer.shadowColor = AppTheme.Shadow.button.color
        addButton.layer.shadowOpacity = AppTheme.Shadow.button.opacity
        addButton.layer.shadowRadius = AppTheme.Shadow.button.radius
        addButton.layer.shadowOffset = AppTheme.Shadow.button.offset
        
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        
        // 按下效果
        addButton.addTarget(self, action: #selector(addButtonTouchDown), for: .touchDown)
        addButton.addTarget(self, action: #selector(addButtonTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }
    
    override func setupConstraints() {
        // 表格視圖約束
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        // 空狀態視圖約束
        emptyStateView.snp.makeConstraints { make in
            make.center.equalTo(view.safeAreaLayoutGuide)
            make.left.right.equalToSuperview().inset(40)
        }
        
        // 新增按鈕約束
        addButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(24)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(24)
            make.width.height.equalTo(56)
        }
    }
    
    override func setupBindings() {
        // 訂閱卡片列表變化
        viewModel.$filteredCards
            .receive(on: DispatchQueue.main)
            .sink { [weak self] cards in
                self?.updateTableView(with: cards)
            }
            .store(in: &cancellables)
        
        // 訂閱空狀態顯示
        viewModel.$shouldShowEmptyState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] shouldShow in
                self?.updateEmptyState(shouldShow)
            }
            .store(in: &cancellables)
        
        // 訂閱載入狀態
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if !isLoading {
                    self?.tableView.refreshControl?.endRefreshing()
                }
            }
            .store(in: &cancellables)
        
        // 訂閱搜尋文字
        searchController.searchBar.textDidChangePublisher
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] searchText in
                self?.viewModel.updateSearchText(searchText)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - UI Updates
    
    /// 更新表格視圖
    private func updateTableView(with cards: [BusinessCard]) {
        let hasCards = !cards.isEmpty
        tableView.isHidden = !hasCards
        
        if hasCards {
            tableView.reloadData()
        }
    }
    
    /// 更新空狀態視圖顯示 (帶動畫)
    private func updateEmptyState(_ shouldShow: Bool) {
        // 如果狀態沒有變化，不執行動畫
        guard emptyStateView.isHidden == shouldShow else { return }
        
        if shouldShow {
            // 顯示空狀態：先設為可見，再執行淡入動畫
            emptyStateView.alpha = 0
            emptyStateView.isHidden = false
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
                self.emptyStateView.alpha = 1
            }
        } else {
            // 隱藏空狀態：執行淡出動畫，再設為隱藏
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
                self.emptyStateView.alpha = 0
            }) { _ in
                self.emptyStateView.isHidden = true
                self.emptyStateView.alpha = 1 // 重置 alpha 值
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func addButtonTapped() {
        // 透過 Coordinator 處理新增名片流程
        coordinatorDelegate?.cardListDidRequestNewCard()
    }
    
    @objc private func refreshControlValueChanged() {
        viewModel.reloadData()
    }
    
    @objc private func addButtonTouchDown() {
        UIView.animate(withDuration: 0.1) {
            self.addButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }
    
    @objc private func addButtonTouchUp() {
        UIView.animate(withDuration: 0.1) {
            self.addButton.transform = .identity
        }
    }
}

// MARK: - UITableViewDataSource

extension CardListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.filteredCards.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: BusinessCardCell.reuseIdentifier,
            for: indexPath
        ) as? BusinessCardCell else {
            return UITableViewCell()
        }
        
        let businessCard = viewModel.filteredCards[indexPath.row]
        
        // 設定 PhotoService 並配置 Cell
        cell.setPhotoService(photoService)
        cell.configure(with: businessCard)
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension CardListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return BusinessCardCell.calculateOptimalCellHeight() // 響應式高度
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let businessCard = viewModel.filteredCards[indexPath.row]
        
        // 透過 Coordinator 處理導航
        coordinatorDelegate?.cardListDidSelectCard(businessCard)
    }
    
    // MARK: - 滑動刪除功能
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        
        let businessCard = viewModel.filteredCards[indexPath.row]
        
        // 使用AlertPresenter顯示確認對話框
        AlertPresenter.shared.showDestructiveConfirmation(
            "確定要刪除「\(businessCard.name)」的名片嗎？",
            title: "刪除名片",
            destructiveTitle: "刪除",
            onConfirm: { [weak self] in
                self?.performDelete(at: indexPath)
            }
        )
    }
    
    /// 執行刪除操作
    /// - Parameter indexPath: 要刪除的索引路徑
    private func performDelete(at indexPath: IndexPath) {
        // 確保索引仍然有效（防止在對話框顯示期間資料變更）
        guard indexPath.row < viewModel.filteredCards.count else {
            print("⚠️ 刪除失敗：索引已失效")
            return
        }
        
        let businessCard = viewModel.filteredCards[indexPath.row]
        
        // 從 ViewModel 刪除資料，UI 會自動更新
        viewModel.deleteCard(at: indexPath.row)
        
        // 顯示成功提示
        ToastPresenter.shared.showSuccess("已刪除「\(businessCard.name)」")
    }
    
}

// MARK: - UISearchResultsUpdating

extension CardListViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        // 搜尋邏輯由 setupBindings 中的 Publisher 處理
    }
}

// MARK: - UISearchBar Extension for Combine

extension UISearchBar {
    var textDidChangePublisher: AnyPublisher<String, Never> {
        NotificationCenter.default
            .publisher(for: UISearchTextField.textDidChangeNotification, object: self.searchTextField)
            .compactMap { ($0.object as? UISearchTextField)?.text ?? "" }
            .eraseToAnyPublisher()
    }
}

// MARK: - Public Methods

extension CardListViewController {
    
    /// 從 Repository 重新載入資料（由 Coordinator 調用）
    /// - Note: 遵循 MVVM+C 架構，只有 Coordinator 可以主動觸發資料載入
    func refreshDataFromRepository() {
        print("🔄 CardListViewController: 收到 Coordinator 重新載入請求")
        viewModel.loadCards()
    }
    
    /// 視圖即將顯示時的資料同步（由 Coordinator 調用）
    /// - Note: 取代 viewWillAppear 中的自動載入，遵循單一職責原則
    func prepareForDisplay() {
        print("🔄 CardListViewController: 準備顯示，檢查資料狀態")
        // 只在必要時重新載入（例如從其他 Tab 或模組返回）
        if viewModel.cards.isEmpty {
            viewModel.loadCards()
        }
    }
}

// MARK: - Testing Helpers

#if DEBUG
extension CardListViewController {
    
    /// 測試專用：檢查 EmptyStateView 是否可見
    var isEmptyStateVisible: Bool {
        return !emptyStateView.isHidden && emptyStateView.alpha > 0
    }
    
    /// 測試專用：檢查 TableView 是否可見
    var isTableViewVisible: Bool {
        return !tableView.isHidden
    }
    
    /// 測試專用：取得當前顯示的 Cell 數量
    var visibleCellCount: Int {
        return tableView.visibleCells.count
    }
    
    /// 測試專用：模擬下拉刷新
    func simulatePullToRefresh() {
        refreshControlValueChanged()
    }
}
#endif
