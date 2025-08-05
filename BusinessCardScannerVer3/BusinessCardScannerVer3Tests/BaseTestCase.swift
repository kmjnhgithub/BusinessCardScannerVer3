import XCTest
import Combine
@testable import BusinessCardScannerVer3

/// 基礎測試類別，提供共用的測試設定和輔助方法
class BaseTestCase: XCTestCase {
    
    // MARK: - Properties
    
    /// Combine cancellables storage
    var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables?.removeAll()
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Test Helpers
    
    /// 等待 Publisher 完成並返回結果
    func awaitPublisher<T: Publisher>(
        _ publisher: T,
        timeout: TimeInterval = 2.0,
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> T.Output where T.Failure == Never {
        
        var result: T.Output?
        let expectation = XCTestExpectation(description: "Awaiting publisher")
        
        publisher
            .sink { output in
                result = output
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: timeout)
        
        guard let unwrappedResult = result else {
            XCTFail("Publisher did not emit any value", file: file, line: line)
            throw TestError.publisherTimeout
        }
        
        return unwrappedResult
    }
    
    /// 等待帶錯誤的 Publisher 完成並返回結果
    func awaitPublisher<T: Publisher>(
        _ publisher: T,
        timeout: TimeInterval = 2.0,
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> Result<T.Output, T.Failure> {
        
        var result: Result<T.Output, T.Failure>?
        let expectation = XCTestExpectation(description: "Awaiting publisher")
        
        publisher
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        result = .failure(error)
                        expectation.fulfill()
                    }
                },
                receiveValue: { output in
                    result = .success(output)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: timeout)
        
        guard let unwrappedResult = result else {
            XCTFail("Publisher did not emit any value", file: file, line: line)
            throw TestError.publisherTimeout
        }
        
        return unwrappedResult
    }
    
    /// 驗證 Publisher 發出指定數量的值
    func expectValues<T: Publisher>(
        from publisher: T,
        count expectedCount: Int,
        timeout: TimeInterval = 2.0,
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> [T.Output] where T.Failure == Never {
        
        var values: [T.Output] = []
        let expectation = XCTestExpectation(description: "Expecting \(expectedCount) values")
        expectation.expectedFulfillmentCount = expectedCount
        
        publisher
            .sink { value in
                values.append(value)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: timeout)
        
        XCTAssertEqual(values.count, expectedCount, "Expected \(expectedCount) values but got \(values.count)", file: file, line: line)
        return values 
    }
}

// MARK: - Test Errors

enum TestError: Error {
    case publisherTimeout
    case unexpectedValue
    case mockError
    
    var localizedDescription: String {
        switch self {
        case .publisherTimeout:
            return "Publisher did not emit a value within the timeout period"
        case .unexpectedValue:
            return "Publisher emitted an unexpected value"
        case .mockError:
            return "Mock service error"
        }
    }
}

// MARK: - Test Extensions

extension XCTestCase {
    
    /// 驗證兩個 Double 值在指定精度內相等
    func assertDoubleEqual(
        _ expression1: Double,
        _ expression2: Double,
        accuracy: Double,
        _ message: String = "",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertEqual(expression1, expression2, accuracy: accuracy, message, file: file, line: line)
    }
    
    /// 驗證陣列為空
    func XCTAssertEmpty<T: Collection>(
        _ collection: T,
        _ message: String = "Collection should be empty",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertTrue(collection.isEmpty, message, file: file, line: line)
    }
    
    /// 驗證陣列不為空
    func XCTAssertNotEmpty<T: Collection>(
        _ collection: T,
        _ message: String = "Collection should not be empty",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertFalse(collection.isEmpty, message, file: file, line: line)
    }
}