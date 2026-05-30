import Flutter
import UIKit
import FinanceKit

// MARK: - Store protocol (enables injection of a mock in tests)

@available(iOS 17.4, *)
protocol FinanceStoreProtocol {
  func authorizationStatus() async throws -> AuthorizationStatus
  func requestAuthorization() async throws -> AuthorizationStatus
  func accounts(query: AccountQuery) async throws -> [Account]
  func accountBalances(query: AccountBalanceQuery) async throws -> [AccountBalance]
  func transactions(query: TransactionQuery) async throws -> [Transaction]
}

@available(iOS 17.4, *)
extension FinanceStore: FinanceStoreProtocol {}

// MARK: - Plugin

@available(iOS 17.4, *)
public class FlutterFinancekitPlugin: NSObject, FlutterPlugin {

  // Injected so tests can substitute a mock without hitting the real FinanceStore.
  let store: any FinanceStoreProtocol

  init(store: any FinanceStoreProtocol = FinanceStore.shared) {
    self.store = store
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "flutter_financekit",
      binaryMessenger: registrar.messenger()
    )

    let txHandler = TransactionStreamHandler()
    FlutterEventChannel(
      name: "flutter_financekit/transaction_updates",
      binaryMessenger: registrar.messenger()
    ).setStreamHandler(txHandler)

    let acctHandler = AccountStreamHandler()
    FlutterEventChannel(
      name: "flutter_financekit/account_updates",
      binaryMessenger: registrar.messenger()
    ).setStreamHandler(acctHandler)

    let instance = FlutterFinancekitPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    Task {
      do {
        switch call.method {
        case "authorizationStatus":
          let status = try await store.authorizationStatus()
          result(encodeStatus(status))

        case "requestAuthorization":
          let status = try await store.requestAuthorization()
          result(encodeStatus(status))

        case "accounts":
          let query = AccountQuery(sortDescriptors: [])
          let accts = try await store.accounts(query: query)
          result(accts.map { encodeAccount($0) })

        case "currentBalance":
          guard let args = call.arguments as? [String: Any],
                let idStr = args["accountId"] as? String,
                let accountId = UUID(uuidString: idStr) else {
            result(FlutterError(code: "INVALID_ARGS", message: "accountId required", details: nil))
            return
          }
          let query = AccountBalanceQuery(
            sortDescriptors: [],
            predicate: #Predicate<AccountBalance> { $0.accountID == accountId }
          )
          let balances = try await store.accountBalances(query: query)
          result(balances.first.map { encodeBalance($0) })

        case "balanceHistory":
          guard let args = call.arguments as? [String: Any],
                let idStr = args["accountId"] as? String,
                let accountId = UUID(uuidString: idStr) else {
            result(FlutterError(code: "INVALID_ARGS", message: "accountId required", details: nil))
            return
          }
          let query = AccountBalanceQuery(
            sortDescriptors: [],
            predicate: #Predicate<AccountBalance> { $0.accountID == accountId }
          )
          let balances = try await store.accountBalances(query: query)
          result(balances.map { encodeBalance($0) })

        case "transactions":
          let args = call.arguments as? [String: Any] ?? [:]
          let txList = try await fetchTransactions(args: args)
          result(txList.map { encodeTransaction($0) })

        default:
          result(FlutterMethodNotImplemented)
        }
      } catch {
        result(FlutterError(code: "FINANCEKIT_ERROR", message: error.localizedDescription, details: nil))
      }
    }
  }

  // MARK: - Fetch

  private func fetchTransactions(args: [String: Any]) async throws -> [Transaction] {
    let query = TransactionQuery(
      sortDescriptors: [SortDescriptor(\.transactionDate, order: .reverse)]
    )
    var txs = try await store.transactions(query: query)

    if let idStr = args["accountId"] as? String, let accountId = UUID(uuidString: idStr) {
      txs = txs.filter { $0.accountID == accountId }
    }
    if let startTs = args["startDate"] as? Int {
      let d = Date(timeIntervalSince1970: TimeInterval(startTs))
      txs = txs.filter { $0.transactionDate >= d }
    }
    if let endTs = args["endDate"] as? Int {
      let d = Date(timeIntervalSince1970: TimeInterval(endTs))
      txs = txs.filter { $0.transactionDate <= d }
    }
    if let limit = args["limit"] as? Int {
      txs = Array(txs.prefix(limit))
    }
    return txs
  }

  // MARK: - Encoders

  func encodeStatus(_ status: AuthorizationStatus) -> String {
    switch status {
    case .authorized: return "authorized"
    case .denied:     return "denied"
    default:          return "notDetermined"
    }
  }

  // Account is an enum: .asset(AssetAccount) or .liability(LiabilityAccount)
  func encodeAccount(_ account: Account) -> [String: Any?] {
    let type: String
    switch account {
    case .asset:      type = "asset"
    case .liability:  type = "liability"
    }
    return [
      "id":              account.id.uuidString,
      "displayName":     account.displayName,
      "accountType":     type,
      "institutionName": account.institutionName,
      "currencyCode":    account.currencyCode,
    ]
  }

  // AccountBalance has available: Balance? and booked: Balance?
  // Balance has amount: CurrencyAmount and asOfDate: Date
  func encodeBalance(_ balance: AccountBalance) -> [String: Any] {
    let availBalance  = balance.available ?? balance.booked
    let bookedBalance = balance.booked    ?? balance.available
    let asOf = availBalance?.asOfDate ?? bookedBalance?.asOfDate ?? Date()

    let fallback: [String: Any] = ["amount": 0.0, "currencyCode": balance.currencyCode]

    return [
      "id":        balance.id.uuidString,
      "accountId": balance.accountID.uuidString,
      "available": availBalance.map  { encodeCurrencyAmount($0.amount) } ?? fallback,
      "booked":    bookedBalance.map { encodeCurrencyAmount($0.amount) } ?? fallback,
      "asOf":      Int(asOf.timeIntervalSince1970),
    ]
  }

  // CurrencyAmount.amount is Decimal
  func encodeCurrencyAmount(_ amount: CurrencyAmount) -> [String: Any] {
    [
      "amount":       (amount.amount as NSDecimalNumber).doubleValue,
      "currencyCode": amount.currencyCode,
    ]
  }

  func encodeTransaction(_ tx: Transaction) -> [String: Any?] {
    [
      "id":                             tx.id.uuidString,
      "accountId":                      tx.accountID.uuidString,
      "amount":                         encodeCurrencyAmount(tx.transactionAmount),
      "transactionType":                encodeTransactionType(tx.transactionType),
      "status":                         encodeTransactionStatus(tx.status),
      "creditDebitIndicator":           tx.creditDebitIndicator == .credit ? "credit" : "debit",
      "transactionDate":                Int(tx.transactionDate.timeIntervalSince1970),
      "merchantName":                   tx.merchantName,
      // MerchantCategoryCode has rawValue: Int16
      "merchantCategoryCode":           tx.merchantCategoryCode.map { String($0.rawValue) },
      "originalTransactionDescription": tx.originalTransactionDescription,
    ]
  }

  private func encodeTransactionType(_ type: TransactionType) -> String {
    switch type {
    case .adjustment:    return "adjustment"
    case .atm:           return "atm"
    case .billPayment:   return "billPayment"
    case .check:         return "check"
    case .deposit:       return "deposit"
    case .directDebit:   return "directDebit"
    case .directDeposit: return "directDeposit"
    case .dividend:      return "dividend"
    case .fee:           return "fee"
    case .interest:      return "interest"
    case .pointOfSale:   return "pointOfSale"
    case .refund:        return "refund"
    case .standingOrder: return "standingOrder"
    case .transfer:      return "transfer"
    case .withdrawal:    return "withdrawal"
    default:             return "unknown"
    }
  }

  private func encodeTransactionStatus(_ status: TransactionStatus) -> String {
    switch status {
    case .authorized: return "authorized"
    case .booked:     return "booked"
    case .memo:       return "memo"
    case .pending:    return "pending"
    default:          return "booked"
    }
  }
}

// MARK: - Event stream handlers

// FinanceStore.History<T> conforms to AsyncSequence, yielding individual model elements.
// With isMonitoring: true it keeps emitting as the store changes.
// We accumulate into an array and re-emit the full list on each change.

@available(iOS 17.4, *)
class TransactionStreamHandler: NSObject, FlutterStreamHandler {
  private var task: Task<Void, Never>?

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    let args = arguments as? [String: Any] ?? [:]
    let accountId = (args["accountId"] as? String).flatMap { UUID(uuidString: $0) }

    task = Task {
      guard let accountId else {
        // No accountId — do a one-shot fetch since transactionHistory requires an account ID
        do {
          let store = FinanceStore.shared
          let query = TransactionQuery(sortDescriptors: [SortDescriptor(\.transactionDate, order: .reverse)])
          let txs = try await store.transactions(query: query)
          let plugin = FlutterFinancekitPlugin()
          await MainActor.run { events(txs.map { plugin.encodeTransaction($0) }) }
        } catch {
          await MainActor.run {
            events(FlutterError(code: "STREAM_ERROR", message: error.localizedDescription, details: nil))
          }
        }
        return
      }

      do {
        let store = FinanceStore.shared
        let plugin = FlutterFinancekitPlugin()
        // accumulated is keyed by id for O(1) upsert/delete
        var accumulated: [UUID: Transaction] = [:]

        // Each element is FinanceStore.Changes<Transaction> with .inserted, .updated, .deleted
        let history = store.transactionHistory(forAccountID: accountId, since: nil, isMonitoring: true)
        for try await changes in history {
          guard !Task.isCancelled else { break }
          for tx in changes.inserted { accumulated[tx.id] = tx }
          for tx in changes.updated  { accumulated[tx.id] = tx }
          for id in changes.deleted  { accumulated.removeValue(forKey: id) }
          let encoded = accumulated.values.map { plugin.encodeTransaction($0) }
          await MainActor.run { events(encoded) }
        }
      } catch {
        await MainActor.run {
          events(FlutterError(code: "STREAM_ERROR", message: error.localizedDescription, details: nil))
        }
      }
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    task?.cancel()
    task = nil
    return nil
  }
}

@available(iOS 17.4, *)
class AccountStreamHandler: NSObject, FlutterStreamHandler {
  private var task: Task<Void, Never>?

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    task = Task {
      do {
        let store = FinanceStore.shared
        let plugin = FlutterFinancekitPlugin()
        var accumulated: [UUID: Account] = [:]

        // Each element is FinanceStore.Changes<Account> with .inserted, .updated, .deleted
        let history = store.accountHistory(since: nil, isMonitoring: true)
        for try await changes in history {
          guard !Task.isCancelled else { break }
          for acct in changes.inserted { accumulated[acct.id] = acct }
          for acct in changes.updated  { accumulated[acct.id] = acct }
          for id in changes.deleted    { accumulated.removeValue(forKey: id) }
          let encoded = accumulated.values.map { plugin.encodeAccount($0) }
          await MainActor.run { events(encoded) }
        }
      } catch {
        await MainActor.run {
          events(FlutterError(code: "STREAM_ERROR", message: error.localizedDescription, details: nil))
        }
      }
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    task?.cancel()
    task = nil
    return nil
  }
}
