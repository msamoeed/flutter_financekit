import 'package:flutter_financekit/flutter_financekit.dart';
import 'package:flutter_financekit/flutter_financekit_method_channel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakePlatform with MockPlatformInterfaceMixin implements FlutterFinancekitPlatform {
  @override
  Future<AuthorizationStatus> authorizationStatus() async => AuthorizationStatus.authorized;

  @override
  Future<AuthorizationStatus> requestAuthorization() async => AuthorizationStatus.authorized;

  @override
  Future<List<FinancialAccount>> accounts() async => [];

  @override
  Future<AccountBalance?> currentBalance(String accountId) async => null;

  @override
  Future<List<AccountBalance>> balanceHistory(String accountId) async => [];

  @override
  Future<List<Transaction>> transactions(TransactionQuery query) async => [];

  @override
  Stream<List<Transaction>> transactionUpdates(TransactionQuery query) => Stream.value([]);

  @override
  Stream<List<FinancialAccount>> accountUpdates() => Stream.value([]);
}

void main() {
  final FlutterFinancekitPlatform initialPlatform = FlutterFinancekitPlatform.instance;

  test('MethodChannelFlutterFinancekit is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterFinancekit>());
  });

  group('FlutterFinancekit delegates to platform', () {
    setUp(() => FlutterFinancekitPlatform.instance = _FakePlatform());

    test('authorizationStatus returns authorized', () async {
      expect(await FlutterFinancekit.authorizationStatus(), AuthorizationStatus.authorized);
    });

    test('requestAuthorization returns authorized', () async {
      expect(await FlutterFinancekit.requestAuthorization(), AuthorizationStatus.authorized);
    });

    test('accounts returns empty list', () async {
      expect(await FlutterFinancekit.accounts(), isEmpty);
    });

    test('currentBalance returns null when not found', () async {
      expect(await FlutterFinancekit.currentBalance('any-id'), isNull);
    });

    test('transactions returns empty list', () async {
      expect(await FlutterFinancekit.transactions(), isEmpty);
    });

    test('transactionUpdates emits a list', () async {
      expect(await FlutterFinancekit.transactionUpdates().first, isEmpty);
    });

    test('accountUpdates emits a list', () async {
      expect(await FlutterFinancekit.accountUpdates().first, isEmpty);
    });
  });
}
