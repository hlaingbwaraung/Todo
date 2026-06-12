<?php

declare(strict_types=1);

/**
 * Seeds demo data (truncates existing rows first).
 *   php server/bin/seed.php            # refuses if properties already exist
 *   php server/bin/seed.php --force    # replaces ALL existing data
 */

$base = dirname(__DIR__);
require $base . '/config.php';

spl_autoload_register(static function (string $class) use ($base): void {
    if (str_starts_with($class, 'App\\')) {
        $path = $base . '/src/' . str_replace('\\', '/', substr($class, 4)) . '.php';
        if (is_file($path)) {
            require $path;
        }
    }
});

use App\Core\Database;

$data = require $base . '/database/seed.php';
$pdo = Database::pdo();
$now = date('Y-m-d H:i:s');

if (!in_array('--force', $argv, true)) {
    $count = 0;
    try {
        $count = (int)$pdo->query('SELECT COUNT(*) FROM properties')->fetchColumn();
    } catch (PDOException) {
        fwrite(STDERR, "Schema not found — run php server/bin/migrate.php first.\n");
        exit(1);
    }
    if ($count > 0) {
        fwrite(STDERR, "Database already contains $count properties — seeding would replace ALL data.\n");
        fwrite(STDERR, "Run with --force to proceed:  php server/bin/seed.php --force\n");
        exit(1);
    }
}

foreach (['devices', 'reservations', 'inquiries', 'favorites', 'property_images', 'properties', 'categories', 'users'] as $table) {
    $pdo->exec("DELETE FROM $table");
}

// Users
$userIds = [];
$stmt = $pdo->prepare(
    'INSERT INTO users (name, email, password_hash, phone, role, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?)'
);
foreach ($data['users'] as $u) {
    $stmt->execute([
        $u['name'], $u['email'],
        password_hash($u['password'], PASSWORD_DEFAULT),
        $u['phone'] ?? null, $u['role'], $now, $now,
    ]);
    $userIds[$u['role']][] = (int)$pdo->lastInsertId();
}

// Categories
$categoryIds = [];
$stmt = $pdo->prepare(
    'INSERT INTO categories (name, name_ja, slug, created_at, updated_at) VALUES (?, ?, ?, ?, ?)'
);
foreach ($data['categories'] as $c) {
    $stmt->execute([$c['name'], $c['name_ja'], $c['slug'], $now, $now]);
    $categoryIds[$c['slug']] = (int)$pdo->lastInsertId();
}

// Properties + images
$propStmt = $pdo->prepare(
    'INSERT INTO properties (
        title, title_ja, description, description_ja, transaction_type, status, is_featured,
        price, management_fee, deposit_months, key_money_months,
        address, address_ja, prefecture, city, latitude, longitude,
        nearest_station, nearest_station_ja, station_walk_min,
        layout, size_sqm, built_year, floor, total_floors, category_id,
        pet_allowed, parking_available, amenities, floor_plan_url,
        agent_name, agent_company, agent_phone, agent_email,
        view_count, created_at, updated_at
     ) VALUES (' . rtrim(str_repeat('?, ', 37), ', ') . ')'
);
$imgStmt = $pdo->prepare(
    'INSERT INTO property_images (property_id, url, sort_order, created_at) VALUES (?, ?, ?, ?)'
);

$propertyIds = [];
foreach ($data['properties'] as $i => $p) {
    // Stagger created_at so "newest" sorting looks natural.
    $createdAt = date('Y-m-d H:i:s', strtotime("-" . (count($data['properties']) - $i) . " days"));
    $propStmt->execute([
        $p['title'], $p['title_ja'], $p['description'], $p['description_ja'],
        $p['transaction_type'], $p['status'], (int)$p['is_featured'],
        $p['price'], $p['management_fee'], $p['deposit_months'], $p['key_money_months'],
        $p['address'], $p['address_ja'], $p['prefecture'], $p['city'],
        $p['latitude'], $p['longitude'],
        $p['nearest_station'], $p['nearest_station_ja'], $p['station_walk_min'],
        $p['layout'], $p['size_sqm'], $p['built_year'], $p['floor'], $p['total_floors'],
        $categoryIds[$p['category']] ?? null,
        (int)$p['pet_allowed'], (int)$p['parking_available'],
        json_encode($p['amenities'], JSON_UNESCAPED_UNICODE),
        $p['floor_plan_url'],
        $p['agent_name'], $p['agent_company'], $p['agent_phone'], $p['agent_email'],
        $p['view_count'], $createdAt, $createdAt,
    ]);
    $propertyId = (int)$pdo->lastInsertId();
    $propertyIds[] = $propertyId;
    foreach ($p['images'] as $order => $url) {
        $imgStmt->execute([$propertyId, $url, $order, $createdAt]);
    }
}

// Demo favorites for the demo user
$demoUserId = $userIds['user'][0];
$favStmt = $pdo->prepare('INSERT INTO favorites (user_id, property_id, created_at) VALUES (?, ?, ?)');
foreach (array_slice($propertyIds, 0, 3) as $pid) {
    $favStmt->execute([$demoUserId, $pid, $now]);
}

// Sample inquiries / reservations spread over the last 7 days (feeds the dashboard chart)
$inquiries = [
    ['Kobayashi Hana', 'hana.k@example.com', '080-1111-2222', 'Is this property still available? I would like to know about the initial costs.'],
    ['Mori Takumi', 'takumi.m@example.com', '090-3333-4444', '内見は週末でも可能でしょうか？よろしくお願いいたします。'],
    ['Nakamura Yui', 'yui.n@example.com', null, 'ペット（小型犬1匹）と一緒に入居を考えています。詳細を教えてください。'],
    ['Alex Chen', 'alex.chen@example.com', '070-5555-6666', 'I am relocating to Tokyo in August. Can you share the floor plan and move-in conditions?'],
    ['Fujita Sora', 'sora.f@example.com', '080-7777-8888', '駐車場の空き状況と月額料金について教えていただけますか。'],
    ['Demo Tanaka', 'demo@happyhome.jp', '090-1234-5678', 'リビングの日当たりについて詳しく知りたいです。'],
];
$inqStmt = $pdo->prepare(
    'INSERT INTO inquiries (property_id, user_id, name, email, phone, message, status, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'
);
foreach ($inquiries as $i => $q) {
    $ts = date('Y-m-d H:i:s', strtotime('-' . ($i % 7) . ' days ' . (9 + $i) . ':15'));
    $status = ['new', 'new', 'in_progress', 'new', 'closed', 'new'][$i];
    $userId = $q[1] === 'demo@happyhome.jp' ? $demoUserId : null;
    $inqStmt->execute([
        $propertyIds[$i % count($propertyIds)], $userId,
        $q[0], $q[1], $q[2], $q[3], $status, $ts, $ts,
    ]);
}

$reservations = [
    ['Kobayashi Hana', 'hana.k@example.com', '080-1111-2222', '+3 days', '11:00', 'Looking forward to it.', 'confirmed'],
    ['Mori Takumi', 'takumi.m@example.com', '090-3333-4444', '+5 days', '14:00', '当日はよろしくお願いします。', 'pending'],
    ['Demo Tanaka', 'demo@happyhome.jp', '090-1234-5678', '+2 days', '16:00', null, 'pending'],
    ['Alex Chen', 'alex.chen@example.com', '070-5555-6666', '+7 days', '10:00', 'Will come with my partner.', 'pending'],
];
$resStmt = $pdo->prepare(
    'INSERT INTO reservations (property_id, user_id, name, email, phone, preferred_date, preferred_time, message, status, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
);
foreach ($reservations as $i => $r) {
    $ts = date('Y-m-d H:i:s', strtotime('-' . ($i % 4) . ' days 1' . $i . ':40'));
    $userId = $r[1] === 'demo@happyhome.jp' ? $demoUserId : null;
    $resStmt->execute([
        $propertyIds[($i * 2) % count($propertyIds)], $userId,
        $r[0], $r[1], $r[2], date('Y-m-d', strtotime($r[3])), $r[4], $r[5], $r[6], $ts, $ts,
    ]);
}

echo sprintf(
    "Seeded: %d users, %d categories, %d properties, %d inquiries, %d reservations.\n",
    count($data['users']), count($data['categories']), count($data['properties']),
    count($inquiries), count($reservations)
);
