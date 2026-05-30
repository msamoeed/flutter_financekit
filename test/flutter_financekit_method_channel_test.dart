import 'package:flutter/services.dart';
import 'package:flutter_financekit/flutter_financekit_method_channel.dart';
import 'package:flutter_financekit/flutter_financekit_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelFlutterFinancekit();
  const channel = MethodChannel('flutter_financekit');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      switch (call.method) {
        case 'authorizationStatus':
          return 'authorized';
        case 'requestAuthorization':
          return 'authorized';
        case 'accounts':
          return <Map<Object?, Object?>>[];
        case 'transactions':
          return <Map<Object?, Object?>>[];
        case 'currentBalance':
          return null;
        case 'balanceHistory':
          return <Map<Object?, Object?>>[];
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('authorizationStatus decodes correctly', () async {
    expect(await platform.authorizationStatus(), AuthorizationStatus.authorized);
  });

  test('requestAuthorization decodes correctly', () async {
    expect(await platform.requestAuthorization(), AuthorizationStatus.authorized);
  });

  test('accounts returns empty list', () async {
    expect(await platform.accounts(), isEmpty);
  });

  test('transactions returns empty list', () async {
    expect(await platform.transactions(const TransactionQuery()), isEmpty);
  });

  test('currentBalance returns null when native returns null', () async {
    expect(await platform.currentBalance('any-id'), isNull);
  });
}
