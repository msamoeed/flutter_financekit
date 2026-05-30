import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_financekit_method_channel.dart';
import 'src/models.dart';

export 'src/models.dart';

/// The interface that platform implementations must extend.
///
/// Platform implementations should extend this class rather than implement it
/// as `flutter_financekit` does not consider newly added methods to be breaking
/// changes. Extending guarantees that the subclass will get the default
/// implementation, while platform implementations that `implements` this
/// interface will be broken by newly added [FlutterFinancekitPlatform] methods.
abstract class FlutterFinancekitPlatform extends PlatformInterface {
  /// Constructs a [FlutterFinancekitPlatform].
  FlutterFinancekitPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterFinancekitPlatform _instance = MethodChannelFlutterFinancekit();

  /// The default instance of [FlutterFinancekitPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterFinancekit].
  static FlutterFinancekitPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterFinancekitPlatform] when
  /// they register themselves.
  static set instance(FlutterFinancekitPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Returns the current FinanceKit authorization status without prompting.
  Future<AuthorizationStatus> authorizationStatus();

  /// Requests FinanceKit authorization, displaying the system prompt if needed.
  Future<AuthorizationStatus> requestAuthorization();

  /// Returns all financial accounts the user has authorized access to.
  Future<List<FinancialAccount>> accounts();

  /// Returns the most recent [AccountBalance] for the given [accountId],
  /// or `null` if no balance is on record.
  Future<AccountBalance?> currentBalance(String accountId);

  /// Returns all stored balance snapshots for the given [accountId].
  Future<List<AccountBalance>> balanceHistory(String accountId);

  /// Returns transactions matching the provided [query].
  Future<List<Transaction>> transactions(TransactionQuery query);

  /// A stream that emits an updated list of transactions whenever FinanceKit
  /// reports a change.
  Stream<List<Transaction>> transactionUpdates(TransactionQuery query);

  /// A stream that emits the full updated account list whenever accounts
  /// are added, modified, or removed.
  Stream<List<FinancialAccount>> accountUpdates();
}
