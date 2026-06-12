<?php

/**
 * Router for PHP's built-in web server:
 *   php -S localhost:8000 -t server/public server/public/router.php
 *
 * Serves existing static files directly; everything else goes to index.php.
 */

$path = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
$file = __DIR__ . $path;

if ($path !== '/' && is_file($file) && pathinfo($file, PATHINFO_EXTENSION) !== 'php') {
    return false; // let the built-in server serve the static file
}

require __DIR__ . '/index.php';
