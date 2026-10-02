# Sadab Invo – drop-in patch

UNVERIFIED: written without access to your repo or a Flutter SDK. Run
`flutter analyze` and `flutter test` yourself before relying on it.

## What's inside
- `lib/sadab_core/`  models (strict JSON), parsing, search, billing, stock, backup
- `lib/sadab_ui/`    responsive shell (bar/rail), Google Drive "Pending" section
- `test/`            tests for parsing, models, billing, stock, search, backup
- `.github/workflows/ci.yml`  analyze + test + APK + Windows ZIP

No new dependencies (only `flutter` and `flutter_test`).

## Install
1. Unzip into the repo root (it only adds new files; nothing is overwritten
   except `.github/workflows/ci.yml` if you already have one — compare first).
2. Package name: tests import `package:sadab_invo/...`. If your pubspec
   `name:` differs, run:
   `grep -rl "package:sadab_invo" test | xargs sed -i 's/package:sadab_invo/package:YOUR_NAME/g'`
3. `flutter pub get && flutter analyze && flutter test`

## Wire into your app
- Storage: implement `BackupStore` over your Hive CE boxes (snapshot +
  replaceAll). Map your existing models to/from `Product`, `Sale`, `Purchase`
  or adapt these models to yours.
- Products/Billing screens: create a `ProductSearchController`, call
  `setProducts()` when data changes, bind `TextField.onChanged` to
  `setQuery()`, render `results` with `ListView.builder` inside a
  `ListenableBuilder`. Dispose it in `dispose()`.
- Billing: `Cart` (ChangeNotifier) + `BillingService.checkout(...)`; persist
  `inventory` and `sale` together, then `cart.clear()`. Catch
  `InsufficientStockException` / `EmptyCartException` and show a SnackBar.
- Stock: `StockService.receive(...)`, persist `product` + `purchase`.
- Restore flow: pick file -> read text -> `BackupService.decode` (validate,
  show counts in a confirm dialog) -> `BackupService.restore` -> refresh UI.
- Shell: `ResponsiveShell(destinations: ResponsiveShell.defaultDestinations,
  pages: [...six pages...])`.

## Not included (needs your repo)
Dashboard, product DataTable layouts, Settings form, theme, real Drive
integration, Android/Windows platform config. Send me those files and I'll
build them against your actual code.
