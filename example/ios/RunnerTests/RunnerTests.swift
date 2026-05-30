import Flutter
import UIKit
import XCTest
import FinanceKit

@testable import flutter_financekit

// MARK: - Mock store

/// A configurable mock that satisfies FinanceStoreProtocol without hitting the real FinanceStore.
@available(iOS 17.4, *)
final class MockFinanceStore: FinanceStoreProtocol {

  // Configure these before each test
  var stubbedAuthStatus: AuthorizationStatus = .authorized
  var stubbedAccounts: [Account] = []
  var stubbedBalances: [AccountBalance] = []
  var stubbedTransactions: [Transaction] = []
  var shouldThrow = false

  private func checkThrow() throws {
    if shouldThrow { throw FinanceError.notAuthorizedToReadData }
  }

  func authorizationStatus() async throws -> AuthorizationStatus {
    try checkThrow()
    return stubbedAuthStatus
  }

  func requestAuthorization() async throws -> AuthorizationStatus {
    try checkThrow()
    return stubbedAuthStatus
  }

  func accounts(query: AccountQuery) async throws -> [Account] {
    try checkThrow()
    return stubbedAccounts
  }

  func accountBalances(query: AccountBalanceQuery) async throws -> [AccountBalance] {
    try checkThrow()
    return stubbedBalances
  }

  func transactions(query: TransactionQuery) async throws -> [Transaction] {
    try checkThrow()
    return stubbedTransactions
  }
}

// MARK: - Helpers

/// Call a plugin method and await the result.
@available(iOS 17.4, *)
@discardableResult
func call(
  _ plugin: FlutterFinancekitPlugin,
  method: String,
  arguments: Any? = nil
) async -> Any? {
  await withCheckedContinuation { continuation in
    let flutterCall = FlutterMethodCall(methodName: method, arguments: arguments)
    plugin.handle(flutterCall) { result in
      continuation.resume(returning: result)
    }
  }
}

// MARK: - Tests

@available(iOS 17.4, *)
class RunnerTests: XCTestCase {

  var mockStore: MockFinanceStore!
  var plugin: FlutterFinancekitPlugin!

  override func setUp() {
    super.setUp()
    mockStore = MockFinanceStore()
    plugin = FlutterFinancekitPlugin(store: mockStore)
  }

  // MARK: Authorization

  func testAuthorizationStatus_authorized() async {
    mockStore.stubbedAuthStatus = .authorized
    let result = await call(plugin, method: "authorizationStatus")
    XCTAssertEqual(result as? String, "authorized")
  }

  func testAuthorizationStatus_denied() async {
    mockStore.stubbedAuthStatus = .denied
    let result = await call(plugin, method: "authorizationStatus")
    XCTAssertEqual(result as? String, "denied")
  }

  func testAuthorizationStatus_notDetermined() async {
    mockStore.stubbedAuthStatus = .notDetermined
    let result = await call(plugin, method: "authorizationStatus")
    XCTAssertEqual(result as? String, "notDetermined")
  }

  func testRequestAuthorization_returnsStatus() async {
    mockStore.stubbedAuthStatus = .authorized
    let result = await call(plugin, method: "requestAuthorization")
    XCTAssertEqual(result as? String, "authorized")
  }

  func testRequestAuthorization_propagatesError() async {
    mockStore.shouldThrow = true
    let result = await call(plugin, method: "requestAuthorization")
    XCTAssertTrue(result is FlutterError)
    let err = result as! FlutterError
    XCTAssertEqual(err.code, "FINANCEKIT_ERROR")
  }

  // MARK: Accounts

  func testAccounts_emptyList() async {
    mockStore.stubbedAccounts = []
    let result = await call(plugin, method: "accounts")
    XCTAssertEqual((result as? [[String: Any?]])?.count, 0)
  }

  func testAccounts_propagatesError() async {
    mockStore.shouldThrow = true
    let result = await call(plugin, method: "accounts")
    XCTAssertTrue(result is FlutterError)
    XCTAssertEqual((result as! FlutterError).code, "FINANCEKIT_ERROR")
  }

  // MARK: Balances

  func testCurrentBalance_missingArguments_returnsInvalidArgs() async {
    let result = await call(plugin, method: "currentBalance", arguments: nil)
    let err = result as? FlutterError
    XCTAssertEqual(err?.code, "INVALID_ARGS")
  }

  func testCurrentBalance_invalidUUID_returnsInvalidArgs() async {
    let result = await call(plugin, method: "currentBalance", arguments: ["accountId": "not-a-uuid"])
    let err = result as? FlutterError
    XCTAssertEqual(err?.code, "INVALID_ARGS")
  }

  func testCurrentBalance_noBalanceFound_returnsNil() async {
    mockStore.stubbedBalances = []
    let id = UUID().uuidString
    let result = await call(plugin, method: "currentBalance", arguments: ["accountId": id])
    XCTAssertTrue(result == nil || result is NSNull)
  }

  func testBalanceHistory_missingArguments_returnsInvalidArgs() async {
    let result = await call(plugin, method: "balanceHistory", arguments: nil)
    XCTAssertEqual((result as? FlutterError)?.code, "INVALID_ARGS")
  }

  // MARK: Transactions

  func testTransactions_emptyResult() async {
    mockStore.stubbedTransactions = []
    let result = await call(plugin, method: "transactions", arguments: [:])
    XCTAssertEqual((result as? [[String: Any?]])?.count, 0)
  }

  func testTransactions_propagatesError() async {
    mockStore.shouldThrow = true
    let result = await call(plugin, method: "transactions", arguments: [:])
    XCTAssertTrue(result is FlutterError)
  }

  // MARK: Encoders

  func testEncodeStatus_allCases() {
    XCTAssertEqual(plugin.encodeStatus(.authorized),    "authorized")
    XCTAssertEqual(plugin.encodeStatus(.denied),        "denied")
    XCTAssertEqual(plugin.encodeStatus(.notDetermined), "notDetermined")
  }

  func testEncodeCurrencyAmount() {
    let amount = CurrencyAmount(amount: 42.5, currencyCode: "USD")
    let map = plugin.encodeCurrencyAmount(amount)
    XCTAssertEqual(map["currencyCode"] as? String, "USD")
    XCTAssertEqual(map["amount"] as? Double, 42.5, accuracy: 0.001)
  }

  // MARK: Unknown method

  func testUnknownMethod_returnsNotImplemented() async {
    let result = await call(plugin, method: "doesNotExist")
    // FlutterMethodNotImplemented is a constant; the result equals it
    XCTAssertTrue(result is FlutterMethodNotImplemented.Type || result == nil || {
      if let r = result as? NSObject { return r === FlutterMethodNotImplemented }
      return false
    }())
  }
}
