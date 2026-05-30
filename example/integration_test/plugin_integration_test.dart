import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_financekit/flutter_financekit.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Enable mock so these tests run without the FinanceKit entitlement.
  setUpAll(MockFinancekitPlatform.enable);

  testWidgets('authorizationStatus returns authorized with mock', (tester) async {
    final status = await FlutterFinancekit.authorizationStatus();
    expect(status, AuthorizationStatus.authorized);
  });

  testWidgets('accounts returns non-empty list with mock', (tester) async {
    final accounts = await FlutterFinancekit.accounts();
    expect(accounts, isNotEmpty);
  });

  testWidgets('transactions returns non-empty list with mock', (tester) async {
    final txs = await FlutterFinancekit.transactions();
    expect(txs, isNotEmpty);
  });

  testWidgets('currentBalance returns a value with mock', (tester) async {
    final accounts = await FlutterFinancekit.accounts();
    final balance = await FlutterFinancekit.currentBalance(accounts.first.id);
    expect(balance, isNotNull);
  });

  testWidgets('transactionUpdates emits a list with mock', (tester) async {
    final txs = await FlutterFinancekit.transactionUpdates().first;
    expect(txs, isNotEmpty);
  });
}
