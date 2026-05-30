/// Data models mirroring Apple FinanceKit types.
library;

/// Whether the app is authorized to access FinanceKit data.
enum AuthorizationStatus {
  /// The user has not yet been asked for authorization.
  notDetermined,

  /// The user has denied access to FinanceKit data.
  denied,

  /// The app is authorized to access FinanceKit data.
  authorized,
}

/// Whether an account holds assets or represents a liability.
enum AccountType {
  /// A deposit account, savings account, or similar asset.
  asset,

  /// A credit card, loan, or similar liability.
  liability,
}

/// The kind of financial transaction.
enum TransactionType {
  /// An unrecognized transaction type.
  unknown,

  /// An adjustment to an account balance.
  adjustment,

  /// An ATM withdrawal or deposit.
  atm,

  /// A bill payment.
  billPayment,

  /// A check.
  check,

  /// A cash or electronic deposit.
  deposit,

  /// A direct debit (pull payment).
  directDebit,

  /// A direct deposit (push payment, e.g. payroll).
  directDeposit,

  /// A dividend payment.
  dividend,

  /// A fee charged by the institution.
  fee,

  /// An interest payment.
  interest,

  /// A point-of-sale purchase.
  pointOfSale,

  /// A refund or reversal.
  refund,

  /// A standing order (recurring payment).
  standingOrder,

  /// A transfer between accounts.
  transfer,

  /// A cash withdrawal.
  withdrawal,
}

/// The settlement status of a transaction.
enum TransactionStatus {
  /// Approved but not yet fully processed.
  authorized,

  /// Settled and posted to the account.
  booked,

  /// A memo or informational entry (no funds movement).
  memo,

  /// Initiated but not yet authorized.
  pending,
}

/// Whether a transaction increases or decreases the account balance.
enum CreditDebitIndicator {
  /// Funds added to the account (income, refund, deposit).
  credit,

  /// Funds removed from the account (purchase, fee, withdrawal).
  debit,
}

/// A monetary amount paired with its ISO 4217 currency code.
class CurrencyAmount {
  /// Creates a [CurrencyAmount] with the given [amount] and [currencyCode].
  const CurrencyAmount({required this.amount, required this.currencyCode});

  /// Deserializes from a native method-channel map.
  factory CurrencyAmount.fromMap(Map<Object?, Object?> map) => CurrencyAmount(
        amount: (map['amount'] as num).toDouble(),
        currencyCode: map['currencyCode'] as String,
      );

  /// The numeric value of the amount.
  final double amount;

  /// The ISO 4217 currency code, e.g. `"USD"` or `"EUR"`.
  final String currencyCode;

  /// Serializes to a method-channel–compatible map.
  Map<String, dynamic> toMap() => {'amount': amount, 'currencyCode': currencyCode};

  @override
  String toString() => '$currencyCode $amount';
}

/// A snapshot of an account's balance at a point in time.
class AccountBalance {
  /// Creates an [AccountBalance].
  const AccountBalance({
    required this.id,
    required this.accountId,
    required this.available,
    required this.booked,
    required this.asOf,
  });

  /// Deserializes from a native method-channel map.
  factory AccountBalance.fromMap(Map<Object?, Object?> map) => AccountBalance(
        id: map['id'] as String,
        accountId: map['accountId'] as String,
        available: CurrencyAmount.fromMap(map['available'] as Map<Object?, Object?>),
        booked: CurrencyAmount.fromMap(map['booked'] as Map<Object?, Object?>),
        asOf: DateTime.fromMillisecondsSinceEpoch((map['asOf'] as int) * 1000),
      );

  /// The unique identifier for this balance record.
  final String id;

  /// The identifier of the account this balance belongs to.
  final String accountId;

  /// The immediately spendable balance.
  final CurrencyAmount available;

  /// The settled (posted) balance.
  final CurrencyAmount booked;

  /// When this balance was calculated.
  final DateTime asOf;
}

/// A financial account linked in Apple Wallet.
class FinancialAccount {
  /// Creates a [FinancialAccount].
  const FinancialAccount({
    required this.id,
    required this.displayName,
    required this.accountType,
    required this.institutionName,
    this.currencyCode,
  });

  /// Deserializes from a native method-channel map.
  factory FinancialAccount.fromMap(Map<Object?, Object?> map) => FinancialAccount(
        id: map['id'] as String,
        displayName: map['displayName'] as String,
        accountType: AccountType.values.byName(map['accountType'] as String),
        institutionName: map['institutionName'] as String,
        currencyCode: map['currencyCode'] as String?,
      );

  /// The unique account identifier (UUID string).
  final String id;

  /// The user-facing name of the account.
  final String displayName;

  /// Whether this is an asset or liability account.
  final AccountType accountType;

  /// The name of the financial institution that holds the account.
  final String institutionName;

  /// The ISO 4217 currency code the account is denominated in, if known.
  final String? currencyCode;
}

/// A financial transaction on an account.
class Transaction {
  /// Creates a [Transaction].
  const Transaction({
    required this.id,
    required this.accountId,
    required this.amount,
    required this.transactionType,
    required this.status,
    required this.creditDebitIndicator,
    required this.transactionDate,
    this.merchantName,
    this.merchantCategoryCode,
    this.originalTransactionDescription,
  });

  /// Deserializes from a native method-channel map.
  factory Transaction.fromMap(Map<Object?, Object?> map) => Transaction(
        id: map['id'] as String,
        accountId: map['accountId'] as String,
        amount: CurrencyAmount.fromMap(map['amount'] as Map<Object?, Object?>),
        transactionType: TransactionType.values.byName(map['transactionType'] as String),
        status: TransactionStatus.values.byName(map['status'] as String),
        creditDebitIndicator:
            CreditDebitIndicator.values.byName(map['creditDebitIndicator'] as String),
        transactionDate:
            DateTime.fromMillisecondsSinceEpoch((map['transactionDate'] as int) * 1000),
        merchantName: map['merchantName'] as String?,
        merchantCategoryCode: map['merchantCategoryCode'] as String?,
        originalTransactionDescription: map['originalTransactionDescription'] as String?,
      );

  /// The unique transaction identifier (UUID string).
  final String id;

  /// The identifier of the account this transaction belongs to.
  final String accountId;

  /// The transaction amount and currency.
  final CurrencyAmount amount;

  /// The category of the transaction.
  final TransactionType transactionType;

  /// The settlement status of the transaction.
  final TransactionStatus status;

  /// Whether this transaction adds or removes funds from the account.
  final CreditDebitIndicator creditDebitIndicator;

  /// When the transaction occurred.
  final DateTime transactionDate;

  /// The merchant name, if available.
  final String? merchantName;

  /// The ISO 18245 merchant category code as a string, if available.
  final String? merchantCategoryCode;

  /// The unmodified description as provided by the financial institution.
  final String? originalTransactionDescription;
}

/// Parameters for filtering a transaction query.
class TransactionQuery {
  /// Creates a [TransactionQuery] with optional filters.
  ///
  /// All parameters are optional. Omit a parameter to apply no filter for
  /// that dimension.
  const TransactionQuery({
    this.accountId,
    this.startDate,
    this.endDate,
    this.limit,
  });

  /// Restrict results to a specific account (UUID string).
  final String? accountId;

  /// Exclude transactions before this date.
  final DateTime? startDate;

  /// Exclude transactions after this date.
  final DateTime? endDate;

  /// Maximum number of transactions to return.
  final int? limit;

  /// Serializes to a method-channel–compatible map.
  Map<String, dynamic> toMap() => {
        if (accountId != null) 'accountId': accountId,
        if (startDate != null) 'startDate': startDate!.millisecondsSinceEpoch ~/ 1000,
        if (endDate != null) 'endDate': endDate!.millisecondsSinceEpoch ~/ 1000,
        if (limit != null) 'limit': limit,
      };
}
