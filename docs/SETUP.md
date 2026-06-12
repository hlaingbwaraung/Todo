# HappyHome — Setup & Deployment Guide

## 1. Server

### Requirements
- PHP 8.1+ with `pdo_mysql` (production) or `pdo_sqlite` (development), `gd`, `mbstring`
- MySQL 8 (production) — SQLite needs nothing
- Apache with `mod_rewrite`, or any server that can front `public/index.php`

### Configuration

All configuration is environment-driven with development defaults
(see `server/config.php`):

| Variable | Default | Notes |
|---|---|---|
| `DB_DRIVER` | `sqlite` | `mysql` or `sqlite` |
| `DB_HOST` | `localhost` | MySQL only |
| `DB_NAME` | `happyhome` | MySQL only |
| `DB_USER` | `root` | MySQL only |
| `DB_PASS` | *(empty)* | MySQL only |
| `DB_SQLITE_PATH` | `server/storage/happyhome.sqlite` | SQLite only |
| `APP_KEY` | dev default | **Set a long random secret in production** |
| `APP_URL` | `http://localhost:8000` | Used for upload URLs |

### Development (SQLite, built-in server)

```bash
php server/bin/migrate.php
php server/bin/seed.php
php -S localhost:8000 -t server/public server/public/router.php
```

### Production (MySQL + Apache)

```bash
mysql -u root -p -e "CREATE DATABASE happyhome CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
export DB_DRIVER=mysql DB_NAME=happyhome DB_USER=... DB_PASS=... APP_KEY="$(openssl rand -hex 32)"
php server/bin/migrate.php
php server/bin/seed.php        # optional demo data
```

Point the Apache `DocumentRoot` at `server/public/` — the included `.htaccess`
routes everything through `index.php`. Set the environment variables via
`SetEnv` or your process manager. Ensure `server/public/uploads/` and
`server/storage/` are writable by the web server user.

**Production checklist**
- Set a strong unique `APP_KEY` (JWT + session secret)
- Serve over HTTPS, then remove the localhost ATS exception from the iOS app
- Change the seeded admin password immediately (or skip seeding and create
  an admin row manually)

## 2. iOS app

### Requirements
- Xcode 15+ (iOS 17 SDK), [XcodeGen](https://github.com/yonaskolb/XcodeGen)

```bash
brew install xcodegen
cd ios/HappyHome
xcodegen generate
open HappyHome.xcodeproj
```

### Pointing the app at your server
- Simulator: works out of the box against `http://localhost:8000`.
- Physical device: open the app → Profile → Settings → API Base URL and enter
  `http://<your-mac-LAN-IP>:8000`. (The dev Info.plist allows local HTTP;
  production builds should use HTTPS only.)

### Push notifications
The app registers for APNs after login and posts the device token to
`POST /api/devices`. To actually deliver pushes you need an Apple Developer
account: enable the Push Notifications capability for the bundle id
(`jp.happyhome.app`), then wire an APNs provider (e.g. token-based JWT auth)
to the stored tokens in the `devices` table.

## 3. Connecting the pieces

The iOS app and the admin dashboard share one database through the same PHP
backend. Anything an admin publishes in `/admin` is immediately visible in the
app; inquiries and viewing reservations submitted in the app appear in the
admin dashboard in real time.
