import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'src/models.dart';
import 'flutter_financekit_method_channel.dart';

export 'src/models.dart';

abstract class FlutterFinancekitPlatform extends PlatformInterface {
  FlutterFinancekitPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterFinancekitPlatform _instance = MethodChannelFlutterFinancekit();

  static FlutterFinancekitPlatform get instance => _instance;

  static set instance(FlutterFinancekitPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<AuthorizationStatus> authorizationStatus();
  Future<AuthorizationStatus> requestAuthorization();
  Future<List<FinancialAccount>> accounts();
  Future<AccountBalance?> currentBalance(String accountId);
  Future<List<AccountBalance>> balanceHistory(String accountId);
  Future<List<Transaction>> transactions(TransactionQuery query);
  Stream<List<Transaction>> transactionUpdates(TransactionQuery query);
  Stream<List<FinancialAccount>> accountUpdates();
}
