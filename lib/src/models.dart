// Data models mirroring Apple FinanceKit types.

enum AuthorizationStatus { notDetermined, denied, authorized }

enum AccountType { asset, liability }

enum TransactionType {
  unknown,
  adjustment,
  atm,
  billPayment,
  check,
  deposit,
  directDebit,
  directDeposit,
  dividend,
  fee,
  interest,
  pointOfSale,
  refund,
  standingOrder,
  transfer,
  withdrawal,
}

enum TransactionStatus { authorized, booked, memo, pending }

enum CreditDebitIndicator { credit, debit }

class CurrencyAmount {
  final double amount;
  final String currencyCode;

  const CurrencyAmount({required this.amount, required this.currencyCode});

  factory CurrencyAmount.fromMap(Map<Object?, Object?> map) => CurrencyAmount(
        amount: (map['amount'] as num).toDouble(),
        currencyCode: map['currencyCode'] as String,
      );

  Map<String, dynamic> toMap() => {'amount': amount, 'currencyCode': currencyCode};

  @override
  String toString() => '$currencyCode $amount';
}

class AccountBalance {
  final String id;
  final String accountId;
  final CurrencyAmount available;
  final CurrencyAmount booked;
  final DateTime asOf;

  const AccountBalance({
    required this.id,
    required this.accountId,
    required this.available,
    required this.booked,
    required this.asOf,
  });

  factory AccountBalance.fromMap(Map<Object?, Object?> map) => AccountBalance(
        id: map['id'] as String,
        accountId: map['accountId'] as String,
        available: CurrencyAmount.fromMap(map['available'] as Map<Object?, Object?>),
        booked: CurrencyAmount.fromMap(map['booked'] as Map<Object?, Object?>),
        asOf: DateTime.fromMillisecondsSinceEpoch((map['asOf'] as int) * 1000),
      );
}

class FinancialAccount {
  final String id;
  final String displayName;
  final AccountType accountType;
  final String institutionName;
  final String? currencyCode;

  const FinancialAccount({
    required this.id,
    required this.displayName,
    required this.accountType,
    required this.institutionName,
    this.currencyCode,
  });

  factory FinancialAccount.fromMap(Map<Object?, Object?> map) => FinancialAccount(
        id: map['id'] as String,
        displayName: map['displayName'] as String,
        accountType: AccountType.values.byName(map['accountType'] as String),
        institutionName: map['institutionName'] as String,
        currencyCode: map['currencyCode'] as String?,
      );
}

class Transaction {
  final String id;
  final String accountId;
  final CurrencyAmount amount;
  final TransactionType transactionType;
  final TransactionStatus status;
  final CreditDebitIndicator creditDebitIndicator;
  final DateTime transactionDate;
  final String? merchantName;
  final String? merchantCategoryCode;
  final String? originalTransactionDescription;

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
}

class TransactionQuery {
  final String? accountId;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? limit;

  const TransactionQuery({
    this.accountId,
    this.startDate,
    this.endDate,
    this.limit,
  });

  Map<String, dynamic> toMap() => {
        if (accountId != null) 'accountId': accountId,
        if (startDate != null) 'startDate': startDate!.millisecondsSinceEpoch ~/ 1000,
        if (endDate != null) 'endDate': endDate!.millisecondsSinceEpoch ~/ 1000,
        if (limit != null) 'limit': limit,
      };
}
