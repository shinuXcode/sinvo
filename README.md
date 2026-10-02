# Sinvo — Offline Shop Manager

Sinvo is a local-first shop inventory, billing and business-management web app.

## Current architecture

- No backend
- No account/login system
- No cloud database
- No Google Drive/Sheets backup
- Data is stored locally on the device/browser with localStorage
- PWA/service-worker support for offline use
- Android APK wrapper is built from the same web app

## Features

- Dashboard
- Product add/edit/delete
- SKU, barcode and category fields
- Stock management and stock ledger
- Low-stock alerts
- Sales and printable invoices
- Cash, UPI, Card and Credit payments
- Customer records and outstanding credit
- Purchases and supplier details
- Expenses
- Revenue, stock-value and net-cash reports
- Search and filtering
- Responsive mobile UI

## Web deployment

GitHub Actions deploys the repository to GitHub Pages after pushes to `main`.

## Android

The `android/` project packages the same app into an Android APK. GitHub Actions builds a debug APK and uploads it as the workflow artifact.

## Data

This version intentionally has no backup or cloud-sync feature. Clearing browser/app storage will remove local shop data, so add backup/export only when you are ready for that feature.
