<?php
/**
 * HappyHome configuration. Environment-driven with sane defaults.
 */

declare(strict_types=1);

date_default_timezone_set('Asia/Tokyo');

if (!function_exists('env')) {
    function env(string $key, mixed $default = null): mixed
    {
        $value = getenv($key);
        if ($value === false || $value === '') {
            return $default;
        }
        return $value;
    }
}

return [
    'db' => [
        'driver'      => strtolower((string)env('DB_DRIVER', 'sqlite')), // mysql | sqlite
        'host'        => env('DB_HOST', '127.0.0.1'),
        'port'        => (int)env('DB_PORT', 3306),
        'name'        => env('DB_NAME', 'happyhome'),
        'user'        => env('DB_USER', 'root'),
        'pass'        => env('DB_PASS', ''),
        'sqlite_path' => env('DB_SQLITE_PATH', __DIR__ . '/storage/happyhome.sqlite'),
    ],
    'app' => [
        'key'  => env('APP_KEY', 'happyhome-dev-secret-change-me-in-production-7f3a9c'),
        'url'  => env('APP_URL', 'http://localhost:8000'),
        'name' => 'HappyHome',
    ],
    'jwt' => [
        'ttl' => 60 * 60 * 24 * 30, // 30 days
    ],
    'uploads' => [
        'dir'        => __DIR__ . '/public/uploads',
        'url_prefix' => '/uploads',
        'max_bytes'  => 8 * 1024 * 1024, // 8 MB
        'mime_ext'   => [
            'image/jpeg' => 'jpg',
            'image/png'  => 'png',
            'image/webp' => 'webp',
        ],
    ],
];
