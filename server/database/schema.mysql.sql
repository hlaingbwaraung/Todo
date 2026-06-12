-- HappyHome schema (MySQL 8, utf8mb4)

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS devices;
DROP TABLE IF EXISTS reservations;
DROP TABLE IF EXISTS inquiries;
DROP TABLE IF EXISTS favorites;
DROP TABLE IF EXISTS property_images;
DROP TABLE IF EXISTS properties;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS users;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE users (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(190) NOT NULL,
    email VARCHAR(190) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(50) NULL,
    role ENUM('user','admin') NOT NULL DEFAULT 'user',
    avatar_url VARCHAR(500) NULL,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE categories (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(190) NOT NULL,
    name_ja VARCHAR(190) NOT NULL,
    slug VARCHAR(190) NOT NULL UNIQUE,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE properties (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    title_ja VARCHAR(255) NOT NULL,
    description TEXT NULL,
    description_ja TEXT NULL,
    transaction_type ENUM('rent','buy') NOT NULL DEFAULT 'rent',
    status ENUM('published','draft') NOT NULL DEFAULT 'draft',
    is_featured TINYINT(1) NOT NULL DEFAULT 0,
    price BIGINT NOT NULL,
    management_fee INT NULL,
    deposit_months DECIMAL(4,1) NULL,
    key_money_months DECIMAL(4,1) NULL,
    address VARCHAR(255) NOT NULL,
    address_ja VARCHAR(255) NOT NULL,
    prefecture VARCHAR(100) NULL,
    city VARCHAR(100) NULL,
    latitude DECIMAL(10,7) NULL,
    longitude DECIMAL(10,7) NULL,
    nearest_station VARCHAR(255) NULL,
    nearest_station_ja VARCHAR(255) NULL,
    station_walk_min INT NULL,
    layout VARCHAR(20) NULL,
    size_sqm DECIMAL(7,1) NULL,
    built_year INT NULL,
    floor INT NULL,
    total_floors INT NULL,
    category_id BIGINT UNSIGNED NULL,
    pet_allowed TINYINT(1) NOT NULL DEFAULT 0,
    parking_available TINYINT(1) NOT NULL DEFAULT 0,
    amenities JSON NULL,
    floor_plan_url VARCHAR(500) NULL,
    agent_name VARCHAR(190) NULL,
    agent_company VARCHAR(190) NULL,
    agent_phone VARCHAR(50) NULL,
    agent_email VARCHAR(190) NULL,
    view_count INT NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    CONSTRAINT fk_properties_category FOREIGN KEY (category_id)
        REFERENCES categories(id) ON DELETE SET NULL,
    INDEX idx_properties_status (status),
    INDEX idx_properties_category (category_id),
    INDEX idx_properties_price (price),
    INDEX idx_properties_layout (layout)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE property_images (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    property_id BIGINT UNSIGNED NOT NULL,
    url VARCHAR(500) NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL,
    CONSTRAINT fk_images_property FOREIGN KEY (property_id)
        REFERENCES properties(id) ON DELETE CASCADE,
    INDEX idx_property_images_property (property_id, sort_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE favorites (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    property_id BIGINT UNSIGNED NOT NULL,
    created_at DATETIME NOT NULL,
    CONSTRAINT fk_favorites_user FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_favorites_property FOREIGN KEY (property_id)
        REFERENCES properties(id) ON DELETE CASCADE,
    UNIQUE KEY uq_favorites_user_property (user_id, property_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE inquiries (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    property_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NULL,
    name VARCHAR(190) NOT NULL,
    email VARCHAR(190) NOT NULL,
    phone VARCHAR(50) NULL,
    message TEXT NOT NULL,
    status ENUM('new','in_progress','closed') NOT NULL DEFAULT 'new',
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    CONSTRAINT fk_inquiries_property FOREIGN KEY (property_id)
        REFERENCES properties(id) ON DELETE CASCADE,
    CONSTRAINT fk_inquiries_user FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_inquiries_property (property_id),
    INDEX idx_inquiries_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE reservations (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    property_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NULL,
    name VARCHAR(190) NOT NULL,
    email VARCHAR(190) NOT NULL,
    phone VARCHAR(50) NULL,
    preferred_date DATE NOT NULL,
    preferred_time VARCHAR(5) NOT NULL,
    message TEXT NULL,
    status ENUM('pending','confirmed','cancelled','completed') NOT NULL DEFAULT 'pending',
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    CONSTRAINT fk_reservations_property FOREIGN KEY (property_id)
        REFERENCES properties(id) ON DELETE CASCADE,
    CONSTRAINT fk_reservations_user FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_reservations_property (property_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE devices (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    device_token VARCHAR(255) NOT NULL,
    platform VARCHAR(20) NOT NULL DEFAULT 'ios',
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    CONSTRAINT fk_devices_user FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY uq_devices_user_token (user_id, device_token)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
