-- HappyHome schema (SQLite)

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS devices;
DROP TABLE IF EXISTS reservations;
DROP TABLE IF EXISTS inquiries;
DROP TABLE IF EXISTS favorites;
DROP TABLE IF EXISTS property_images;
DROP TABLE IF EXISTS properties;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    phone TEXT NULL,
    role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user','admin')),
    avatar_url TEXT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE TABLE categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    name_ja TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE TABLE properties (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    title_ja TEXT NOT NULL,
    description TEXT NULL,
    description_ja TEXT NULL,
    transaction_type TEXT NOT NULL DEFAULT 'rent' CHECK (transaction_type IN ('rent','buy')),
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('published','draft')),
    is_featured INTEGER NOT NULL DEFAULT 0,
    price INTEGER NOT NULL,
    management_fee INTEGER NULL,
    deposit_months REAL NULL,
    key_money_months REAL NULL,
    address TEXT NOT NULL,
    address_ja TEXT NOT NULL,
    prefecture TEXT NULL,
    city TEXT NULL,
    latitude REAL NULL,
    longitude REAL NULL,
    nearest_station TEXT NULL,
    nearest_station_ja TEXT NULL,
    station_walk_min INTEGER NULL,
    layout TEXT NULL,
    size_sqm REAL NULL,
    built_year INTEGER NULL,
    floor INTEGER NULL,
    total_floors INTEGER NULL,
    category_id INTEGER NULL REFERENCES categories(id) ON DELETE SET NULL,
    pet_allowed INTEGER NOT NULL DEFAULT 0,
    parking_available INTEGER NOT NULL DEFAULT 0,
    amenities TEXT NULL,
    floor_plan_url TEXT NULL,
    agent_name TEXT NULL,
    agent_company TEXT NULL,
    agent_phone TEXT NULL,
    agent_email TEXT NULL,
    view_count INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE INDEX idx_properties_status ON properties(status);
CREATE INDEX idx_properties_category ON properties(category_id);
CREATE INDEX idx_properties_price ON properties(price);
CREATE INDEX idx_properties_layout ON properties(layout);

CREATE TABLE property_images (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    property_id INTEGER NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    url TEXT NOT NULL,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL
);

CREATE INDEX idx_property_images_property ON property_images(property_id, sort_order);

CREATE TABLE favorites (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    property_id INTEGER NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    created_at TEXT NOT NULL,
    UNIQUE (user_id, property_id)
);

CREATE TABLE inquiries (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    property_id INTEGER NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    user_id INTEGER NULL REFERENCES users(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT NULL,
    message TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'new' CHECK (status IN ('new','in_progress','closed')),
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE INDEX idx_inquiries_property ON inquiries(property_id);
CREATE INDEX idx_inquiries_created ON inquiries(created_at);

CREATE TABLE reservations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    property_id INTEGER NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    user_id INTEGER NULL REFERENCES users(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT NULL,
    preferred_date TEXT NOT NULL,
    preferred_time TEXT NOT NULL,
    message TEXT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','confirmed','cancelled','completed')),
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE INDEX idx_reservations_property ON reservations(property_id);

CREATE TABLE devices (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_token TEXT NOT NULL,
    platform TEXT NOT NULL DEFAULT 'ios',
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    UNIQUE (user_id, device_token)
);
