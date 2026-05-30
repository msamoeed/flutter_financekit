# flutter_financekit

A Flutter plugin for Apple's [FinanceKit](https://developer.apple.com/documentation/financekit) framework, giving you access to financial accounts, balances, and transactions stored in Apple Wallet.

**iOS 17.4+ only.** Android is not supported — FinanceKit is an Apple-exclusive framework.

---

## Features

- Check and request FinanceKit authorization
- Fetch all linked financial accounts
- Fetch current and historical account balances
- Fetch transactions with filtering by account, date range, and limit
- Live streams for real-time transaction and account updates

---

## Requirements

| Requirement | Detail |
|---|---|
| iOS | 17.4+ |
| Flutter | 3.3+ |
| Xcode | 15+ |
| Apple entitlement | `com.apple.developer.financekit` (must be requested from Apple) |

> **Important:** FinanceKit requires a special entitlement that Apple grants manually. You must apply at [developer.apple.com/contact/request/financekit](https://developer.apple.com/contact/request/financekit) with a paid Apple Developer account before financial data can be read on a real device.

---

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_financekit: ^1.0.0
```

### iOS setup

1. **Set deployment target to iOS 17.4** in your `ios/Podfile`:
   ```ruby
   platform :ios, '17.4'
   ```
   And in Xcode: **Runner → General → Minimum Deployments → iOS 17.4**.

2. **Add the usage description** to `ios/Runner/Info.plist`:
   ```xml
   <key>NSFinancialDataUsageDescription</key>
   <string>This app uses FinanceKit to display your financial accounts and transactions.</string>
   ```

3. **Add the FinanceKit capability** in Xcode:
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select the Runner target → **Signing & Capabilities**
   - Click **+ Capability** and add **FinanceKit**
   - This requires the entitlement to have been approved by Apple

---

## Usage

### Authorization

Always check authorization before accessing data:

```dart
import 'package:flutter_financekit/flutter_financekit.dart';

// Check current status without prompting
final status = await FlutterFinancekit.authorizationStatus();

// Prompt the user to grant access
final status = await FlutterFinancekit.requestAuthorization();

if (status == AuthorizationStatus.authorized) {
  // Access financial data
}
```

### Accounts

```dart
final accounts = await FlutterFinancekit.accounts();

for (final account in accounts) {
  print(account.displayName);       // e.g. "Apple Card"
  print(account.institutionName);   // e.g. "Goldman Sachs"
  print(account.accountType);       // AccountType.asset or .liability
  print(account.currencyCode);      // e.g. "USD"
}
```

### Balances

```dart
// Most recent balance for an account
final balance = await FlutterFinancekit.currentBalance(account.id);

print(balance?.booked.amount);      // e.g. 1234.56
print(balance?.available.amount);   // available to spend
print(balance?.booked.currencyCode); // e.g. "USD"

// All stored balance snapshots
final history = await FlutterFinancekit.balanceHistory(account.id);
```

### Transactions

```dart
// All transactions
final txs = await FlutterFinancekit.transactions();

// Filtered
final txs = await FlutterFinancekit.transactions(
  TransactionQuery(
    accountId: account.id,
    startDate: DateTime(2025, 1, 1),
    endDate: DateTime.now(),
    limit: 100,
  ),
);

for (final tx in txs) {
  print(tx.merchantName);              // e.g. "Starbucks"
  print(tx.amount.amount);             // e.g. 4.50
  print(tx.amount.currencyCode);       // e.g. "USD"
  print(tx.creditDebitIndicator);      // CreditDebitIndicator.debit
  print(tx.transactionType);           // TransactionType.pointOfSale
  print(tx.status);                    // TransactionStatus.booked
  print(tx.transactionDate);           // DateTime
}
```

### Live streams

```dart
// Stream account changes
FlutterFinancekit.accountUpdates().listen((accounts) {
  print('Accounts updated: ${accounts.length}');
});

// Stream transaction changes for a specific account
FlutterFinancekit.transactionUpdates(
  TransactionQuery(accountId: account.id),
).listen((transactions) {
  print('Transactions updated: ${transactions.length}');
});
```

---

## Data models

### `FinancialAccount`

| Property | Type | Description |
|---|---|---|
| `id` | `String` | Unique account ID (UUID) |
| `displayName` | `String` | User-facing account name |
| `accountType` | `AccountType` | `.asset` or `.liability` |
| `institutionName` | `String` | Bank or institution name |
| `currencyCode` | `String?` | ISO 4217 currency code |

### `AccountBalance`

| Property | Type | Description |
|---|---|---|
| `id` | `String` | Unique balance ID |
| `accountId` | `String` | Owning account ID |
| `available` | `CurrencyAmount` | Available (spendable) balance |
| `booked` | `CurrencyAmount` | Booked (settled) balance |
| `asOf` | `DateTime` | When the balance was calculated |

### `Transaction`

| Property | Type | Description |
|---|---|---|
| `id` | `String` | Unique transaction ID |
| `accountId` | `String` | Owning account ID |
| `amount` | `CurrencyAmount` | Transaction amount and currency |
| `transactionType` | `TransactionType` | e.g. `.pointOfSale`, `.transfer` |
| `status` | `TransactionStatus` | `.booked`, `.pending`, `.authorized`, `.memo` |
| `creditDebitIndicator` | `CreditDebitIndicator` | `.credit` or `.debit` |
| `transactionDate` | `DateTime` | When the transaction occurred |
| `merchantName` | `String?` | Merchant name if available |
| `merchantCategoryCode` | `String?` | ISO 18245 category code |
| `originalTransactionDescription` | `String?` | Raw description from the institution |

### `TransactionQuery`

| Property | Type | Description |
|---|---|---|
| `accountId` | `String?` | Filter to a specific account |
| `startDate` | `DateTime?` | Earliest transaction date |
| `endDate` | `DateTime?` | Latest transaction date |
| `limit` | `int?` | Maximum number of results |

---

## Testing without the entitlement

During development, use the built-in mock platform to get realistic fake data on Simulator or any device:

```dart
void main() {
  MockFinancekitPlatform.enable(); // swap in fake data
  runApp(const MyApp());
}
```

Or conditionally via a compile-time flag:

```dart
const _useMock = bool.fromEnvironment('USE_MOCK', defaultValue: false);

void main() {
  if (_useMock) MockFinancekitPlatform.enable();
  runApp(const MyApp());
}
```

```bash
flutter run --dart-define=USE_MOCK=true
```

The mock provides 3 accounts and 6 transactions covering common types (purchase, deposit, refund, pending, transfer).

---

## Entitlement approval process

1. Enrol in the [Apple Developer Program](https://developer.apple.com/programs/) ($99/yr)
2. Submit a request at [developer.apple.com/contact/request/financekit](https://developer.apple.com/contact/request/financekit)
3. Apple reviews your use case (approval is not guaranteed)
4. Once approved, add the FinanceKit capability in Xcode
5. Build and test on a physical device with Apple Wallet accounts linked

---

## License

MIT
