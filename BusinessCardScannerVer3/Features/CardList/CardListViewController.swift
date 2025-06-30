//
//  CardListViewController.swift
//  BusinessCardScannerVer3
//
//  名片列表視圖控制器
//

import UIKit
import SnapKit
import Combine

class CardListViewController: BaseViewController {
    
    // MARK: - UI Elements
    
    private let tableView = UITableView()
    private let searchController = UISearchController(searchResultsController: nil)
    private let emptyStateView = EmptyStateView()
    private let addButton = UIButton(type: .system)
    
    // MARK: - Properties
    
    private var viewModel: CardListViewModel!
    
    // MARK: - Initialization
    
    init(viewModel: CardListViewModel) {
        self.viewModel = viewModel
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
        
        // 每次進入頁面重新載入資料
        viewModel.loadCards()
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
            message: "點擊 + 新增第一張名片",
            actionTitle: "新增名片"
        )
        
        emptyStateView.actionHandler = { [weak self] in
            self?.addButtonTapped()
        }
        
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
                self?.updateUI(with: cards)
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
    
    private func updateUI(with cards: [BusinessCard]) {
        let isEmpty = cards.isEmpty
        tableView.isHidden = isEmpty
        emptyStateView.isHidden = !isEmpty
        
        if !isEmpty {
            tableView.reloadData()
        }
    }
    
    // MARK: - Actions
    
    @objc private func addButtonTapped() {
        // TODO: 觸發新增名片流程 (Task 3.4 實作)
        print("新增按鈕被點擊")
    }
    
    @objc private func refreshControlValueChanged() {
        viewModel.loadCards()
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
        cell.configure(with: businessCard)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension CardListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 88 // 根據UI設計規範
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let businessCard = viewModel.filteredCards[indexPath.row]
        // TODO: 導航到詳情頁面 (後續實作)
        print("選中名片: \(businessCard.name ?? "未知")")
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