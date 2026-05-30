## 1.0.0+1

* Initial release.
* Authorization: check and request FinanceKit access.
* Accounts: fetch all linked financial accounts.
* Balances: fetch current and historical account balances.
* Transactions: fetch and filter by account, date range, and limit.
* Streaming: live `Stream` updates for account and transaction changes via `FinanceStore.History`.
* Mock: built-in `MockFinancekitPlatform` for UI development without the FinanceKit entitlement.
* Requires iOS 17.4+ and the `com.apple.developer.financekit` entitlement.
