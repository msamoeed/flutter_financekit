import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_financekit/flutter_financekit.dart';

const bool _useMock = bool.fromEnvironment('USE_MOCK', defaultValue: false);

void main() {
  if (_useMock) MockFinancekitPlatform.enable();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinanceKit Demo',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AuthorizationStatus _status = AuthorizationStatus.notDetermined;
  List<FinancialAccount> _accounts = [];
  List<Transaction> _transactions = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final status = await FlutterFinancekit.authorizationStatus();
      setState(() => _status = status);
      if (status == AuthorizationStatus.authorized) _loadData();
    } on PlatformException catch (e) {
      setState(() => _error = e.message);
    }
  }

  Future<void> _requestAuthorization() async {
    setState(() => _loading = true);
    try {
      final status = await FlutterFinancekit.requestAuthorization();
      setState(() => _status = status);
      if (status == AuthorizationStatus.authorized) await _loadData();
    } on PlatformException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final accounts = await FlutterFinancekit.accounts();
      final transactions = await FlutterFinancekit.transactions(
        const TransactionQuery(limit: 50),
      );
      setState(() {
        _accounts = accounts;
        _transactions = transactions;
        _error = null;
      });
    } on PlatformException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('FinanceKit'),
          bottom: const TabBar(tabs: [
            Tab(icon: Icon(Icons.account_balance), text: 'Accounts'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Transactions'),
          ]),
          actions: [
            if (_loading) const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            if (!_loading && _status == AuthorizationStatus.authorized)
              IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          ],
        ),
        body: Column(
          children: [
            _StatusBanner(
              status: _status,
              error: _error,
              onRequest: _requestAuthorization,
            ),
            Expanded(
              child: TabBarView(children: [
                _AccountsTab(accounts: _accounts),
                _TransactionsTab(transactions: _transactions),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final AuthorizationStatus status;
  final String? error;
  final VoidCallback onRequest;

  const _StatusBanner({required this.status, required this.error, required this.onRequest});

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return MaterialBanner(
        content: Text(error!),
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        actions: [TextButton(onPressed: () {}, child: const Text('OK'))],
      );
    }
    return switch (status) {
      AuthorizationStatus.notDetermined => MaterialBanner(
          content: const Text('FinanceKit access not yet requested.'),
          actions: [
            TextButton(onPressed: onRequest, child: const Text('Authorize')),
          ],
        ),
      AuthorizationStatus.denied => MaterialBanner(
          content: const Text('FinanceKit access denied. Enable it in Settings > Privacy.'),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          actions: [TextButton(onPressed: () {}, child: const Text('OK'))],
        ),
      AuthorizationStatus.authorized => const SizedBox.shrink(),
    };
  }
}

class _AccountsTab extends StatelessWidget {
  final List<FinancialAccount> accounts;
  const _AccountsTab({required this.accounts});

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return const Center(child: Text('No accounts found.'));
    }
    return ListView.builder(
      itemCount: accounts.length,
      itemBuilder: (_, i) {
        final a = accounts[i];
        return ListTile(
          leading: Icon(
            a.accountType == AccountType.asset ? Icons.account_balance_wallet : Icons.credit_card,
          ),
          title: Text(a.displayName),
          subtitle: Text(a.institutionName),
          trailing: Text(a.currencyCode ?? ''),
        );
      },
    );
  }
}

class _TransactionsTab extends StatelessWidget {
  final List<Transaction> transactions;
  const _TransactionsTab({required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const Center(child: Text('No transactions found.'));
    }
    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (_, i) {
        final tx = transactions[i];
        final isDebit = tx.creditDebitIndicator == CreditDebitIndicator.debit;
        return ListTile(
          leading: Icon(
            isDebit ? Icons.arrow_upward : Icons.arrow_downward,
            color: isDebit ? Colors.red : Colors.green,
          ),
          title: Text(tx.merchantName ?? tx.originalTransactionDescription ?? 'Transaction'),
          subtitle: Text(
            '${tx.transactionDate.year}-${tx.transactionDate.month.toString().padLeft(2, '0')}-${tx.transactionDate.day.toString().padLeft(2, '0')}  •  ${tx.status.name}',
          ),
          trailing: Text(
            '${isDebit ? '-' : '+'}${tx.amount.currencyCode} ${tx.amount.amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: isDebit ? Colors.red : Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}
