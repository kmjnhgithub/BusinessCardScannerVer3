//
//  BaseViewModelTests.swift
//  BusinessCardScannerVer3Tests
//
//  Created by Claude on 2025-08-05.
//

import XCTest
import Combine
@testable import BusinessCardScannerVer3

/// BaseViewModel 單元測試
/// 測試目標：載入狀態管理、錯誤處理、Combine Publisher 行為、記憶體管理
final class BaseViewModelTests: BaseTestCase {
    
    // MARK: - Test Properties
    
    private var viewModel: TestableBaseViewModel!
    private var mockContainer: MockServiceContainer!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        
        // 使用 MockServiceContainer 統一管理
        mockContainer = MockServiceContainer.shared
        mockContainer.resetToDefaults()
        
        // 創建測試用的 BaseViewModel 子類別
        viewModel = TestableBaseViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        mockContainer = nil
        super.tearDown()
    }
    
    // MARK: - 載入狀態管理測試
    
    func testBaseViewModel_initialState_shouldBeNotLoading() {
        // Given - ViewModel 剛初始化
        
        // When - 檢查初始狀態
        
        // Then - 應該不在載入狀態且無錯誤
        XCTAssertFalse(viewModel.isLoading, "初始狀態不應該在載入中")
        XCTAssertNil(viewModel.error, "初始狀態不應該有錯誤")
        XCTAssertFalse(viewModel.hasError, "初始狀態不應該有錯誤標記")
    }
    
    func testBaseViewModel_startLoading_shouldUpdateState() {
        // Given - ViewModel 初始狀態
        XCTAssertFalse(viewModel.isLoading)
        
        // When - 開始載入
        viewModel.startLoading()
        
        // Then - 載入狀態應該更新
        XCTAssertTrue(viewModel.isLoading, "開始載入後應該處於載入狀態")
        XCTAssertNil(viewModel.error, "開始載入時應該清除錯誤")
    }
    
    func testBaseViewModel_stopLoading_shouldUpdateState() {
        // Given - ViewModel 處於載入狀態
        viewModel.startLoading()
        XCTAssertTrue(viewModel.isLoading)
        
        // When - 停止載入
        viewModel.stopLoading()
        
        // Then - 載入狀態應該更新
        XCTAssertFalse(viewModel.isLoading, "停止載入後不應該處於載入狀態")
    }
    
    func testBaseViewModel_handleError_shouldUpdateErrorState() {
        // Given - ViewModel 初始狀態和測試錯誤
        let testError = NSError(domain: "TestError", code: 123, userInfo: [NSLocalizedDescriptionKey: "測試錯誤"])
        
        // When - 處理錯誤
        viewModel.handleError(testError)
        
        // Then - 錯誤狀態應該更新
        XCTAssertNotNil(viewModel.error, "處理錯誤後應該有錯誤狀態")
        XCTAssertTrue(viewModel.hasError, "處理錯誤後 hasError 應該為 true")
        XCTAssertFalse(viewModel.isLoading, "處理錯誤後應該停止載入")
        
        if let error = viewModel.error as NSError? {
            XCTAssertEqual(error.domain, "TestError")
            XCTAssertEqual(error.code, 123)
        }
    }
    
    func testBaseViewModel_clearError_shouldResetErrorState() {
        // Given - ViewModel 有錯誤狀態
        let testError = NSError(domain: "TestError", code: 123)
        viewModel.handleError(testError)
        XCTAssertTrue(viewModel.hasError)
        
        // When - 清除錯誤
        viewModel.clearError()
        
        // Then - 錯誤狀態應該被清除
        XCTAssertNil(viewModel.error, "清除錯誤後不應該有錯誤狀態")
        XCTAssertFalse(viewModel.hasError, "清除錯誤後 hasError 應該為 false")
    }
    
    // MARK: - Combine Publisher 行為測試
    
    func testBaseViewModel_isLoadingPublisher_shouldEmitCorrectValues() {
        // Given - ViewModel 初始狀態
        var receivedValues: [Bool] = []
        let expectation = expectation(description: "isLoadingPublisher")
        expectation.expectedFulfillmentCount = 3 // initial + start + stop
        
        // When - 訂閱 isLoadingPublisher
        viewModel.isLoadingPublisher
            .sink { value in
                receivedValues.append(value)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // 模擬載入狀態變化
        viewModel.startLoading()
        viewModel.stopLoading()
        
        // Then - 應該收到正確的值序列
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedValues, [false, true, false], "isLoadingPublisher 應該按順序發送正確的值")
    }
    
    func testBaseViewModel_errorPublisher_shouldEmitWhenErrorOccurs() {
        // Given - ViewModel 初始狀態和測試錯誤
        let testError = NSError(domain: "TestError", code: 456)
        var receivedError: Error?
        let expectation = expectation(description: "errorPublisher")
        
        // When - 訂閱 errorPublisher
        viewModel.errorPublisher
            .dropFirst() // 跳過初始的 nil 值
            .sink { error in
                receivedError = error
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        viewModel.handleError(testError)
        
        // Then - 應該收到錯誤
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(receivedError, "errorPublisher 應該發送錯誤")
        
        if let error = receivedError as NSError? {
            XCTAssertEqual(error.domain, "TestError")
            XCTAssertEqual(error.code, 456)
        }
    }
    
    func testBaseViewModel_hasErrorPublisher_shouldEmitCorrectBooleanValues() {
        // Given - ViewModel 初始狀態
        let testError = NSError(domain: "TestError", code: 789)
        var receivedValues: [Bool] = []
        let expectation = expectation(description: "hasErrorPublisher")
        expectation.expectedFulfillmentCount = 3 // initial + error + clear
        
        // When - 訂閱 hasErrorPublisher
        viewModel.hasErrorPublisher
            .sink { hasError in
                receivedValues.append(hasError)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // 模擬錯誤狀態變化
        viewModel.handleError(testError)
        viewModel.clearError()
        
        // Then - 應該按順序收到正確的布林值
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedValues, [false, true, false], "hasErrorPublisher 應該按順序發送正確的布林值")
    }
    
    // MARK: - 非同步操作測試
    
    func testBaseViewModel_performAsyncOperation_success_shouldHandleCorrectly() {
        // Given - 成功的非同步操作
        let expectedResult = "成功結果"
        var receivedResult: String?
        let expectation = expectation(description: "asyncOperation success")
        
        // When - 執行非同步操作
        viewModel.performAsyncOperation(
            operation: {
                // 模擬非同步操作延遲
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 秒
                return expectedResult
            },
            onSuccess: { result in
                receivedResult = result
                expectation.fulfill()
            }
        )
        
        // Then - 應該正確處理成功結果
        wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(receivedResult, expectedResult, "應該收到正確的成功結果")
        XCTAssertFalse(viewModel.isLoading, "操作完成後不應該處於載入狀態")
        XCTAssertNil(viewModel.error, "成功操作不應該有錯誤")
    }
    
    func testBaseViewModel_performAsyncOperation_failure_shouldHandleError() {
        // Given - 失敗的非同步操作
        let expectedError = NSError(domain: "AsyncError", code: 999, userInfo: [NSLocalizedDescriptionKey: "非同步操作失敗"])
        var receivedError: Error?
        let expectation = expectation(description: "asyncOperation failure")
        
        // When - 執行會失敗的非同步操作
        viewModel.performAsyncOperation(
            operation: {
                try await Task.sleep(nanoseconds: 100_000_000)
                throw expectedError
            },
            onSuccess: { _ in
                XCTFail("不應該執行成功回調")
            },
            onError: { error in
                receivedError = error
                expectation.fulfill()
            }
        )
        
        // Then - 應該正確處理錯誤
        wait(for: [expectation], timeout: 2.0)
        XCTAssertNotNil(receivedError, "應該收到錯誤")
        XCTAssertFalse(viewModel.isLoading, "操作失敗後不應該處於載入狀態")
        XCTAssertNotNil(viewModel.error, "應該設定錯誤狀態")
        
        if let error = receivedError as NSError? {
            XCTAssertEqual(error.domain, "AsyncError")
            XCTAssertEqual(error.code, 999)
        }
    }
    
    func testBaseViewModel_performPublisherOperation_success_shouldHandleCorrectly() {
        // Given - 成功的 Publisher 操作
        let expectedResult = "Publisher 成功結果"
        var receivedResult: String?
        let expectation = expectation(description: "publisher success")
        
        let successPublisher = Just(expectedResult)
            .setFailureType(to: Error.self)
            .delay(for: .milliseconds(100), scheduler: DispatchQueue.global())
            .eraseToAnyPublisher()
        
        // When - 執行 Publisher 操作
        viewModel.performPublisherOperation(
            publisher: successPublisher,
            onSuccess: { result in
                receivedResult = result
                expectation.fulfill()
            }
        )
        
        // Then - 應該正確處理成功結果
        wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(receivedResult, expectedResult, "應該收到正確的 Publisher 結果")
        XCTAssertFalse(viewModel.isLoading, "Publisher 完成後不應該處於載入狀態")
        XCTAssertNil(viewModel.error, "成功的 Publisher 不應該有錯誤")
    }
    
    func testBaseViewModel_performPublisherOperation_failure_shouldHandleError() {
        // Given - 失敗的 Publisher 操作
        let expectedError = NSError(domain: "PublisherError", code: 888, userInfo: [NSLocalizedDescriptionKey: "Publisher 操作失敗"])
        var receivedError: Error?
        let expectation = expectation(description: "publisher failure")
        
        let failurePublisher = Fail<String, Error>(error: expectedError)
            .delay(for: .milliseconds(100), scheduler: DispatchQueue.global())
            .eraseToAnyPublisher()
        
        // When - 執行會失敗的 Publisher 操作
        viewModel.performPublisherOperation(
            publisher: failurePublisher,
            onSuccess: { _ in
                XCTFail("不應該執行成功回調")
            },
            onError: { error in
                receivedError = error
                expectation.fulfill()
            }
        )
        
        // Then - 應該正確處理錯誤
        wait(for: [expectation], timeout: 2.0)
        XCTAssertNotNil(receivedError, "應該收到 Publisher 錯誤")
        XCTAssertFalse(viewModel.isLoading, "Publisher 失敗後不應該處於載入狀態")
        XCTAssertNotNil(viewModel.error, "應該設定錯誤狀態")
        
        if let error = receivedError as NSError? {
            XCTAssertEqual(error.domain, "PublisherError")
            XCTAssertEqual(error.code, 888)
        }
    }
    
    // MARK: - 記憶體管理測試
    
    func testBaseViewModel_deinit_shouldBeCalledWhenReleased() {
        // Given - 創建一個 ViewModel 實例
        var testViewModel: TestableBaseViewModel? = TestableBaseViewModel()
        weak var weakViewModel = testViewModel
        
        // When - 釋放 ViewModel
        testViewModel = nil
        
        // Then - 應該正確釋放記憶體
        XCTAssertNil(weakViewModel, "ViewModel 應該被正確釋放，不應該有記憶體洩漏")
    }
    
    func testBaseViewModel_cancellables_shouldBeManagedCorrectly() {
        // Given - ViewModel 和一個 Publisher
        let testPublisher = Just("test")
            .delay(for: .seconds(1), scheduler: DispatchQueue.main)
        
        // When - 訂閱 Publisher
        testPublisher
            .sink { _ in }
            .store(in: &viewModel.cancellables)
        
        // Then - cancellables 應該包含訂閱
        XCTAssertFalse(viewModel.cancellables.isEmpty, "cancellables 應該包含 Publisher 訂閱")
        
        // When - ViewModel 被釋放時，訂閱應該自動取消
        viewModel = nil
        
        // 這裡無法直接測試 cancellables 的自動清理，但在實際使用中 deinit 會自動處理
    }
}

// MARK: - TestableBaseViewModel

/// 用於測試的 BaseViewModel 子類別
private class TestableBaseViewModel: BaseViewModel {
    
    var setupBindingsCalled = false
    
    override func setupBindings() {
        super.setupBindings()
        setupBindingsCalled = true
    }
    
    // 暴露 performAsyncOperation 和 performPublisherOperation 方法供測試使用
    public override func performAsyncOperation<T>(
        operation: @escaping () async throws -> T,
        onSuccess: @escaping (T) -> Void,
        onError: ((Error) -> Void)? = nil
    ) {
        super.performAsyncOperation(operation: operation, onSuccess: onSuccess, onError: onError)
    }
    
    public override func performPublisherOperation<T>(
        publisher: AnyPublisher<T, Error>,
        onSuccess: @escaping (T) -> Void,
        onError: ((Error) -> Void)? = nil
    ) {
        super.performPublisherOperation(publisher: publisher, onSuccess: onSuccess, onError: onError)
    }
}