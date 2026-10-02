# Sinvo

Offline-first shop inventory, billing and business management.

## Architecture
- React + TypeScript + Vite
- IndexedDB for local device/browser data
- PWA/offline cache for the web app
- Android WebView wrapper builds the same web app into an APK
- No login, backend, cloud database or cloud sync

## Core workflows
Products → stock → search → billing → stock deduction → sales history → customer credit → reports.

Local JSON export/import is provided for manual backup.