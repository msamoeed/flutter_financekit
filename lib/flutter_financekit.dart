/// A Flutter plugin for Apple FinanceKit.
///
/// Provides access to financial accounts, balances, and transactions stored
/// in Apple Wallet on iOS 17.4+. Requires the
/// `com.apple.developer.financekit` entitlement.
///
/// ## Quick start
///
/// ```dart
/// import 'package:flutter_financekit/flutter_financekit.dart';
///
/// final status = await FlutterFinancekit.requestAuthorization();
/// if (status == AuthorizationStatus.authorized) {
///   final accounts = await FlutterFinancekit.accounts();
///   final txs = await FlutterFinancekit.transactions();
/// }
/// ```
///
/// ## Testing without the entitlement
///
/// Enable `MockFinancekitPlatform` at app startup to use built-in fake data:
///
/// ```dart
/// void main() {
///   MockFinancekitPlatform.enable();
///   runApp(const MyApp());
/// }
/// ```
library;

import 'flutter_financekit_platform_interface.dart';

export 'flutter_financekit_platform_interface.dart';
export 'src/mock_platform.dart';

/// Main entry point for the flutter_financekit plugin.
///
/// All methods are static. The plugin targets iOS 17.4+ only;
/// calling any method on an unsupported platform throws a `PlatformException`.
class FlutterFinancekit {
  FlutterFinancekit._();

  static FlutterFinancekitPlatform get _p => FlutterFinancekitPlatform.instance;

  /// Returns the current authorization status without prompting the user.
  ///
  /// Check this before calling [requestAuthorization] to avoid an unnecessary
  /// prompt when the user has already granted or denied access.
  static Future<AuthorizationStatus> authorizationStatus() =>
      _p.authorizationStatus();

  /// Prompts the user to grant access to FinanceKit data and returns the
  /// resulting [AuthorizationStatus].
  ///
  /// If the user has already made a decision, the system prompt is skipped and
  /// the existing status is returned immediately.
  static Future<AuthorizationStatus> requestAuthorization() =>
      _p.requestAuthorization();

  /// Returns all financial accounts the user has authorized access to.
  ///
  /// Throws a `PlatformException` if authorization has not been granted.
  static Future<List<FinancialAccount>> accounts() => _p.accounts();

  /// Returns the most recent [AccountBalance] for [accountId], or `null` if
  /// no balance record exists.
  ///
  /// The [accountId] must be a UUID string as returned by [accounts].
  static Future<AccountBalance?> currentBalance(String accountId) =>
      _p.currentBalance(accountId);

  /// Returns all stored balance snapshots for [accountId] in reverse
  /// chronological order.
  ///
  /// The [accountId] must be a UUID string as returned by [accounts].
  static Future<List<AccountBalance>> balanceHistory(String accountId) =>
      _p.balanceHistory(accountId);

  /// Fetches transactions matching [query].
  ///
  /// All [TransactionQuery] fields are optional. Omitting [query] entirely
  /// returns all available transactions.
  ///
  /// ```dart
  /// final txs = await FlutterFinancekit.transactions(
  ///   TransactionQuery(
  ///     accountId: myAccount.id,
  ///     startDate: DateTime(2025, 1, 1),
  ///     limit: 50,
  ///   ),
  /// );
  /// ```
  static Future<List<Transaction>> transactions([
    TransactionQuery query = const TransactionQuery(),
  ]) =>
      _p.transactions(query);

  /// A stream that emits an updated transaction list whenever FinanceKit
  /// reports a change.
  ///
  /// Supply a [TransactionQuery] with a [TransactionQuery.accountId] to
  /// receive live updates via `FinanceStore.transactionHistory`. Without an
  /// account ID a one-time snapshot is emitted.
  static Stream<List<Transaction>> transactionUpdates([
    TransactionQuery query = const TransactionQuery(),
  ]) =>
      _p.transactionUpdates(query);

  /// A stream that emits the full account list whenever accounts are
  /// added, modified, or removed.
  static Stream<List<FinancialAccount>> accountUpdates() => _p.accountUpdates();
}
