/// Method-channel implementation of [FlutterFinancekitPlatform].
library;

import 'package:flutter/services.dart';

import 'flutter_financekit_platform_interface.dart';

class MethodChannelFlutterFinancekit extends FlutterFinancekitPlatform {
  static const _channel = MethodChannel('flutter_financekit');
  static const _transactionEvents = EventChannel('flutter_financekit/transaction_updates');
  static const _accountEvents = EventChannel('flutter_financekit/account_updates');

  @override
  Future<AuthorizationStatus> authorizationStatus() async {
    final status = await _channel.invokeMethod<String>('authorizationStatus');
    return _parseStatus(status!);
  }

  @override
  Future<AuthorizationStatus> requestAuthorization() async {
    final status = await _channel.invokeMethod<String>('requestAuthorization');
    return _parseStatus(status!);
  }

  @override
  Future<List<FinancialAccount>> accounts() async {
    final list = await _channel.invokeListMethod<Map<Object?, Object?>>('accounts');
    return (list ?? []).map(FinancialAccount.fromMap).toList();
  }

  @override
  Future<AccountBalance?> currentBalance(String accountId) async {
    final map = await _channel.invokeMapMethod<Object?, Object?>(
      'currentBalance',
      {'accountId': accountId},
    );
    return map == null ? null : AccountBalance.fromMap(map);
  }

  @override
  Future<List<AccountBalance>> balanceHistory(String accountId) async {
    final list = await _channel.invokeListMethod<Map<Object?, Object?>>(
      'balanceHistory',
      {'accountId': accountId},
    );
    return (list ?? []).map(AccountBalance.fromMap).toList();
  }

  @override
  Future<List<Transaction>> transactions(TransactionQuery query) async {
    final list = await _channel.invokeListMethod<Map<Object?, Object?>>(
      'transactions',
      query.toMap(),
    );
    return (list ?? []).map(Transaction.fromMap).toList();
  }

  @override
  Stream<List<Transaction>> transactionUpdates(TransactionQuery query) {
    return _transactionEvents
        .receiveBroadcastStream(query.toMap())
        .map((event) => (event as List).cast<Map<Object?, Object?>>().map(Transaction.fromMap).toList());
  }

  @override
  Stream<List<FinancialAccount>> accountUpdates() {
    return _accountEvents
        .receiveBroadcastStream()
        .map((event) => (event as List).cast<Map<Object?, Object?>>().map(FinancialAccount.fromMap).toList());
  }

  AuthorizationStatus _parseStatus(String s) {
    return switch (s) {
      'authorized' => AuthorizationStatus.authorized,
      'denied' => AuthorizationStatus.denied,
      _ => AuthorizationStatus.notDetermined,
    };
  }
}
