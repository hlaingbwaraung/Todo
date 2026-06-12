# HappyHome API Contract (v1)

Base URL: `http://<host>/api`
All responses are JSON. All timestamps are ISO-8601 (`YYYY-MM-DDTHH:MM:SS+09:00`).
Authentication: `Authorization: Bearer <token>` (JWT HS256).

## Response envelope

Success:
```json
{ "data": { ... } }
```
List endpoints add pagination meta:
```json
{ "data": [ ... ], "meta": { "page": 1, "per_page": 20, "total": 124, "total_pages": 7 } }
```
Error:
```json
{ "error": { "code": "validation_error", "message": "Email is required.", "fields": { "email": "Email is required." } } }
```
HTTP codes: 200, 201, 400 (validation), 401, 403, 404, 422, 500.

## Models

### User
```json
{ "id": 1, "name": "Tanaka Yuki", "email": "yuki@example.com", "phone": "090-1234-5678",
  "role": "user", "avatar_url": null, "created_at": "..." }
```
`role`: `user` | `admin`. `password_hash` is never returned.

### Property
```json
{
  "id": 1,
  "title": "Sunny 2LDK near Shibuya Station",
  "title_ja": "渋谷駅近くの陽当たり良好2LDK",
  "description": "...",
  "description_ja": "...",
  "transaction_type": "rent",            // "rent" | "buy"
  "status": "published",                 // "published" | "draft"
  "is_featured": true,
  "price": 185000,                       // JPY. Monthly rent if rent, sale price if buy
  "management_fee": 10000,               // JPY/month, nullable
  "deposit_months": 1.0,                 // nullable
  "key_money_months": 1.0,               // nullable
  "address": "1-2-3 Dogenzaka, Shibuya-ku, Tokyo",
  "address_ja": "東京都渋谷区道玄坂1-2-3",
  "prefecture": "Tokyo",
  "city": "Shibuya-ku",
  "latitude": 35.6580,
  "longitude": 139.6994,
  "nearest_station": "Shibuya Station (JR Yamanote Line)",
  "nearest_station_ja": "渋谷駅（JR山手線）",
  "station_walk_min": 5,
  "layout": "2LDK",                      // 1R,1K,1DK,1LDK,2K,2DK,2LDK,3LDK,4LDK+
  "size_sqm": 55.3,
  "built_year": 2018,
  "building_age_years": 8,               // computed server-side
  "floor": 7,
  "total_floors": 12,
  "category_id": 2,
  "category": { "id": 2, "name": "Apartment", "name_ja": "マンション", "slug": "apartment" },
  "pet_allowed": true,
  "parking_available": false,
  "amenities": ["autolock", "balcony", "air_conditioner", "bath_toilet_separate",
                "delivery_box", "internet_free", "system_kitchen", "floor_heating"],
  "floor_plan_url": "https://.../floorplan.png",   // nullable
  "agent_name": "Sato Kenji",
  "agent_company": "HappyHome Realty K.K.",
  "agent_phone": "03-1234-5678",
  "agent_email": "agent@happyhome.jp",
  "images": [ { "id": 10, "url": "https://...", "sort_order": 0 } ],
  "thumbnail_url": "https://...",        // first image, present in list responses
  "view_count": 320,
  "is_favorite": false,                  // only when authenticated
  "created_at": "...", "updated_at": "..."
}
```
List responses return the same shape minus `description*` and `images` (keep `thumbnail_url`).

### Category
```json
{ "id": 1, "name": "Apartment", "name_ja": "マンション", "slug": "apartment", "property_count": 12 }
```

### Inquiry
```json
{ "id": 1, "property_id": 3, "user_id": null, "name": "...", "email": "...", "phone": "...",
  "message": "...", "status": "new", "created_at": "..." }
```
`status`: `new` | `in_progress` | `closed`.

### Reservation (viewing booking)
```json
{ "id": 1, "property_id": 3, "user_id": 2, "name": "...", "email": "...", "phone": "...",
  "preferred_date": "2026-06-20", "preferred_time": "14:00", "message": "...",
  "status": "pending", "created_at": "..." }
```
`status`: `pending` | `confirmed` | `cancelled` | `completed`.

## Endpoints

### Auth
| Method | Path | Auth | Body / Notes |
|---|---|---|---|
| POST | `/api/auth/register` | – | `{name,email,password,phone?}` → `{data:{token,user}}`. Password min 8 chars. |
| POST | `/api/auth/login` | – | `{email,password}` → `{data:{token,user}}` |
| GET | `/api/auth/me` | Bearer | → `{data:user}` |
| PUT | `/api/auth/me` | Bearer | `{name?,phone?,password?,current_password?}` → `{data:user}` |

### Properties
| Method | Path | Auth | Notes |
|---|---|---|---|
| GET | `/api/properties` | optional | Filters below. Only `published` returned. |
| GET | `/api/properties/{id}` | optional | Full detail incl. `images`. Increments `view_count`. |
| GET | `/api/properties/{id}/similar` | optional | Up to 6 published properties: same category or layout, closest in price. |
| GET | `/api/categories` | – | All categories with counts. |

`GET /api/properties` query params (all optional, combinable):
`q` (matches title/address/station, EN+JA), `transaction_type` (`rent`|`buy`),
`min_price`, `max_price` (JPY), `layout` (comma-separated, e.g. `1LDK,2LDK`),
`min_size`, `max_size` (sqm), `max_age` (building age years), `station` (substring),
`max_walk_min`, `pet_allowed` (1), `parking` (1), `category` (slug or id),
`featured` (1), `sort` (`newest`|`price_asc`|`price_desc`|`size_desc`),
`page` (default 1), `per_page` (default 20, max 50).

### Favorites (Bearer required)
| Method | Path | Notes |
|---|---|---|
| GET | `/api/favorites` | List of full Property objects (list shape). |
| POST | `/api/favorites` | `{property_id}` → 201 |
| DELETE | `/api/favorites/{property_id}` | → 200 |

### Inquiries & Reservations
| Method | Path | Auth | Notes |
|---|---|---|---|
| POST | `/api/inquiries` | optional | `{property_id,name,email,phone?,message}` → 201 |
| POST | `/api/reservations` | optional | `{property_id,name,email,phone?,preferred_date,preferred_time,message?}` → 201. Date must be today or later. |
| GET | `/api/me/inquiries` | Bearer | Own inquiries, with property thumbnail/title. |
| GET | `/api/me/reservations` | Bearer | Own reservations, with property thumbnail/title. |

### Devices (push notifications)
| Method | Path | Auth | Notes |
|---|---|---|---|
| POST | `/api/devices` | Bearer | `{device_token, platform:"ios"}` — upsert per user+token. |

## Admin web dashboard

Server-rendered at `/admin` (session auth, admins only; CSRF token on all POST forms).
Pages: login, dashboard (counts + recent inquiries/reservations + simple charts),
properties list (search/filter/paginate, publish toggle, featured toggle),
property create/edit (all fields, multi-image upload + URL input, drag sort optional),
inquiries (status workflow), reservations (status workflow), users list (role change, delete),
categories CRUD. Image uploads stored under `server/public/uploads/` (jpg/png/webp, max 8 MB, randomized names).

## Database

Tables: `users`, `categories`, `properties`, `property_images`, `favorites`
(unique user+property), `inquiries`, `reservations`, `devices`.
Engine: MySQL 8 (utf8mb4) in production; identical schema must also run on SQLite for dev.
`amenities` stored as JSON text. Money stored as integer JPY.

## Config

`server/config.php` reads environment with sane defaults:
`DB_DRIVER` (`mysql`|`sqlite`), `DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASS`,
`DB_SQLITE_PATH`, `APP_KEY` (JWT/session secret), `APP_URL`.
