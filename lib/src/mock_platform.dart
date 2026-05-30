import '../flutter_financekit_platform_interface.dart';

class MockFinancekitPlatform extends FlutterFinancekitPlatform {
  static void enable() {
    FlutterFinancekitPlatform.instance = MockFinancekitPlatform();
  }

  @override
  Future<AuthorizationStatus> authorizationStatus() async =>
      AuthorizationStatus.authorized;

  @override
  Future<AuthorizationStatus> requestAuthorization() async =>
      AuthorizationStatus.authorized;

  @override
  Future<List<FinancialAccount>> accounts() async => _accounts;

  @override
  Future<AccountBalance?> currentBalance(String accountId) async {
    return _balances.where((b) => b.accountId == accountId).firstOrNull;
  }

  @override
  Future<List<AccountBalance>> balanceHistory(String accountId) async =>
      _balances.where((b) => b.accountId == accountId).toList();

  @override
  Future<List<Transaction>> transactions([TransactionQuery query = const TransactionQuery()]) async {
    var result = List<Transaction>.from(_transactions);
    if (query.accountId != null) {
      result = result.where((t) => t.accountId == query.accountId).toList();
    }
    if (query.startDate != null) {
      result = result.where((t) => t.transactionDate.isAfter(query.startDate!)).toList();
    }
    if (query.endDate != null) {
      result = result.where((t) => t.transactionDate.isBefore(query.endDate!)).toList();
    }
    if (query.limit != null) result = result.take(query.limit!).toList();
    return result;
  }

  @override
  Stream<List<Transaction>> transactionUpdates([TransactionQuery query = const TransactionQuery()]) =>
      Stream.value(_transactions);

  @override
  Stream<List<FinancialAccount>> accountUpdates() => Stream.value(_accounts);
}

// ── Fake data ──────────────────────────────────────────────────────────────

final _accounts = [
  const FinancialAccount(
    id: 'acc-1',
    displayName: 'Apple Card',
    accountType: AccountType.liability,
    institutionName: 'Goldman Sachs',
    currencyCode: 'USD',
  ),
  const FinancialAccount(
    id: 'acc-2',
    displayName: 'Checking Account',
    accountType: AccountType.asset,
    institutionName: 'Chase',
    currencyCode: 'USD',
  ),
  const FinancialAccount(
    id: 'acc-3',
    displayName: 'Savings Account',
    accountType: AccountType.asset,
    institutionName: 'Chase',
    currencyCode: 'USD',
  ),
];

final _balances = [
  AccountBalance(
    id: 'bal-1',
    accountId: 'acc-1',
    available: const CurrencyAmount(amount: 1240.50, currencyCode: 'USD'),
    booked: const CurrencyAmount(amount: 1300.00, currencyCode: 'USD'),
    asOf: DateTime.now(),
  ),
  AccountBalance(
    id: 'bal-2',
    accountId: 'acc-2',
    available: const CurrencyAmount(amount: 5820.00, currencyCode: 'USD'),
    booked: const CurrencyAmount(amount: 5820.00, currencyCode: 'USD'),
    asOf: DateTime.now(),
  ),
  AccountBalance(
    id: 'bal-3',
    accountId: 'acc-3',
    available: const CurrencyAmount(amount: 12500.00, currencyCode: 'USD'),
    booked: const CurrencyAmount(amount: 12500.00, currencyCode: 'USD'),
    asOf: DateTime.now(),
  ),
];

final _transactions = [
  Transaction(
    id: 'tx-1',
    accountId: 'acc-1',
    amount: const CurrencyAmount(amount: 4.50, currencyCode: 'USD'),
    transactionType: TransactionType.pointOfSale,
    status: TransactionStatus.booked,
    creditDebitIndicator: CreditDebitIndicator.debit,
    transactionDate: DateTime.now().subtract(const Duration(days: 1)),
    merchantName: 'Starbucks',
    merchantCategoryCode: '5814',
  ),
  Transaction(
    id: 'tx-2',
    accountId: 'acc-1',
    amount: const CurrencyAmount(amount: 120.00, currencyCode: 'USD'),
    transactionType: TransactionType.pointOfSale,
    status: TransactionStatus.booked,
    creditDebitIndicator: CreditDebitIndicator.debit,
    transactionDate: DateTime.now().subtract(const Duration(days: 2)),
    merchantName: 'Amazon',
    merchantCategoryCode: '5999',
  ),
  Transaction(
    id: 'tx-3',
    accountId: 'acc-2',
    amount: const CurrencyAmount(amount: 3500.00, currencyCode: 'USD'),
    transactionType: TransactionType.directDeposit,
    status: TransactionStatus.booked,
    creditDebitIndicator: CreditDebitIndicator.credit,
    transactionDate: DateTime.now().subtract(const Duration(days: 3)),
    originalTransactionDescription: 'Payroll',
  ),
  Transaction(
    id: 'tx-4',
    accountId: 'acc-2',
    amount: const CurrencyAmount(amount: 1800.00, currencyCode: 'USD'),
    transactionType: TransactionType.transfer,
    status: TransactionStatus.booked,
    creditDebitIndicator: CreditDebitIndicator.debit,
    transactionDate: DateTime.now().subtract(const Duration(days: 4)),
    originalTransactionDescription: 'Rent Payment',
  ),
  Transaction(
    id: 'tx-5',
    accountId: 'acc-1',
    amount: const CurrencyAmount(amount: 59.99, currencyCode: 'USD'),
    transactionType: TransactionType.pointOfSale,
    status: TransactionStatus.pending,
    creditDebitIndicator: CreditDebitIndicator.debit,
    transactionDate: DateTime.now().subtract(const Duration(hours: 3)),
    merchantName: 'Netflix',
    merchantCategoryCode: '7812',
  ),
  Transaction(
    id: 'tx-6',
    accountId: 'acc-1',
    amount: const CurrencyAmount(amount: 15.00, currencyCode: 'USD'),
    transactionType: TransactionType.refund,
    status: TransactionStatus.booked,
    creditDebitIndicator: CreditDebitIndicator.credit,
    transactionDate: DateTime.now().subtract(const Duration(days: 5)),
    merchantName: 'Amazon',
    originalTransactionDescription: 'Refund for order #123',
  ),
];
