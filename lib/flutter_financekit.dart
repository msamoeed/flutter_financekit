export 'flutter_financekit_platform_interface.dart';
export 'src/mock_platform.dart';

import 'flutter_financekit_platform_interface.dart';

class FlutterFinancekit {
  static FlutterFinancekitPlatform get _p => FlutterFinancekitPlatform.instance;

  /// Returns the current authorization status without prompting the user.
  static Future<AuthorizationStatus> authorizationStatus() => _p.authorizationStatus();

  /// Prompts the user to grant access to FinanceKit data.
  static Future<AuthorizationStatus> requestAuthorization() => _p.requestAuthorization();

  /// Returns all financial accounts the user has granted access to.
  static Future<List<FinancialAccount>> accounts() => _p.accounts();

  /// Returns the most recent balance for [accountId].
  static Future<AccountBalance?> currentBalance(String accountId) =>
      _p.currentBalance(accountId);

  /// Returns all stored balance snapshots for [accountId].
  static Future<List<AccountBalance>> balanceHistory(String accountId) =>
      _p.balanceHistory(accountId);

  /// Fetches transactions matching [query].
  static Future<List<Transaction>> transactions([TransactionQuery query = const TransactionQuery()]) =>
      _p.transactions(query);

  /// A stream that emits updated transaction lists whenever FinanceKit notifies of changes.
  static Stream<List<Transaction>> transactionUpdates([
    TransactionQuery query = const TransactionQuery(),
  ]) =>
      _p.transactionUpdates(query);

  /// A stream that emits the updated account list whenever accounts change.
  static Stream<List<FinancialAccount>> accountUpdates() => _p.accountUpdates();
}
