# HappyHome — Premium Real Estate Platform

A complete, production-quality real estate platform for the Japanese market:

| Part | Tech | Path |
|---|---|---|
| iOS app | SwiftUI · iOS 17+ · MVVM | [`ios/HappyHome`](ios/HappyHome) |
| REST API | PHP 8.1+ · MySQL / SQLite · JWT | [`server`](server) |
| Admin dashboard | Server-rendered PHP · session auth | [`server`](server) → `/admin` |
| API contract | Markdown spec | [`docs/API.md`](docs/API.md) |

Users can **search, filter, view, favorite, compare, inquire about, and book viewings**
for rental and purchase properties. Admins manage properties, images, categories,
users, inquiries, and reservations from a responsive web dashboard connected to the
same database. Full English + Japanese localization, dark mode, offline caching.

## Quick start

### 1. Server (API + admin)

Development (zero config — uses SQLite):

```bash
php server/bin/migrate.php
php server/bin/seed.php
php -S localhost:8000 -t server/public server/public/router.php
```

- API: `http://localhost:8000/api/properties`
- Admin: `http://localhost:8000/admin`
  - Admin login: `admin@happyhome.jp` / `HappyHome2026!`
  - Demo user: `demo@happyhome.jp` / `Demo12345!`

Production (MySQL + Apache): see [`docs/SETUP.md`](docs/SETUP.md).

### 2. iOS app

```bash
cd ios/HappyHome
xcodegen generate        # brew install xcodegen (once)
open HappyHome.xcodeproj
```

Run on a simulator — the app points at `http://localhost:8000` by default.
For a real device, set your Mac's LAN IP in Profile → Settings → API Base URL.

## Documentation

- [`docs/API.md`](docs/API.md) — full REST API contract
- [`docs/SETUP.md`](docs/SETUP.md) — production setup, MySQL config, deployment notes
