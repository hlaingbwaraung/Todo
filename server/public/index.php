<?php

declare(strict_types=1);

/**
 * HappyHome front controller — routes /api/* (JSON) and /admin/* (server-rendered).
 */

error_reporting(E_ALL);
ini_set('display_errors', '0');

$base = dirname(__DIR__);
require $base . '/config.php'; // sets timezone

// ---- Simple PSR-4-ish autoloader: App\ => server/src/ ----
spl_autoload_register(static function (string $class) use ($base): void {
    $prefix = 'App\\';
    if (!str_starts_with($class, $prefix)) {
        return;
    }
    $path = $base . '/src/' . str_replace('\\', '/', substr($class, strlen($prefix))) . '.php';
    if (is_file($path)) {
        require $path;
    }
});

// ---- Global template escape helper ----
if (!function_exists('e')) {
    function e(mixed $value): string
    {
        return htmlspecialchars((string)($value ?? ''), ENT_QUOTES, 'UTF-8');
    }
}

use App\Controllers\Admin\AuthAdminController;
use App\Controllers\Admin\CategoryAdminController;
use App\Controllers\Admin\DashboardController;
use App\Controllers\Admin\InquiryAdminController;
use App\Controllers\Admin\PropertyAdminController;
use App\Controllers\Admin\ReservationAdminController;
use App\Controllers\Admin\UserAdminController;
use App\Controllers\Api\AuthController;
use App\Controllers\Api\CategoryController;
use App\Controllers\Api\DeviceController;
use App\Controllers\Api\FavoriteController;
use App\Controllers\Api\InquiryController;
use App\Controllers\Api\PropertyController;
use App\Controllers\Api\ReservationController;
use App\Core\Request;
use App\Core\Response;
use App\Core\Router;

$request = new Request();
$isApi = str_starts_with($request->path, '/api');

// ---- CORS for /api/* ----
if ($isApi) {
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Authorization, Content-Type, Accept');
    header('Access-Control-Max-Age: 86400');
    if ($request->method === 'OPTIONS') {
        http_response_code(204);
        exit;
    }
}

// ---- Uncaught exception handler ----
set_exception_handler(static function (\Throwable $e) use ($isApi): void {
    error_log('[HappyHome] ' . $e->getMessage() . ' @ ' . $e->getFile() . ':' . $e->getLine());
    if ($isApi) {
        http_response_code(500);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode(['error' => ['code' => 'server_error', 'message' => 'Internal server error.']]);
    } else {
        http_response_code(500);
        header('Content-Type: text/html; charset=utf-8');
        echo '<h1>500 Internal Server Error</h1>';
    }
    exit;
});

$router = new Router();

// ---------- API routes ----------
$auth = new AuthController();
$router->post('/api/auth/register', [$auth, 'register']);
$router->post('/api/auth/login', [$auth, 'login']);
$router->get('/api/auth/me', [$auth, 'me']);
$router->put('/api/auth/me', [$auth, 'updateMe']);

$properties = new PropertyController();
$router->get('/api/properties', [$properties, 'index']);
$router->get('/api/properties/{id}', [$properties, 'show']);
$router->get('/api/properties/{id}/similar', [$properties, 'similar']);

$categories = new CategoryController();
$router->get('/api/categories', [$categories, 'index']);

$favorites = new FavoriteController();
$router->get('/api/favorites', [$favorites, 'index']);
$router->post('/api/favorites', [$favorites, 'store']);
$router->delete('/api/favorites/{property_id}', [$favorites, 'destroy']);

$inquiries = new InquiryController();
$router->post('/api/inquiries', [$inquiries, 'store']);
$router->get('/api/me/inquiries', [$inquiries, 'mine']);

$reservations = new ReservationController();
$router->post('/api/reservations', [$reservations, 'store']);
$router->get('/api/me/reservations', [$reservations, 'mine']);

$devices = new DeviceController();
$router->post('/api/devices', [$devices, 'store']);

// ---------- Admin routes ----------
$adminAuth = new AuthAdminController();
$router->get('/admin/login', [$adminAuth, 'showLogin']);
$router->post('/admin/login', [$adminAuth, 'login']);
$router->post('/admin/logout', [$adminAuth, 'logout']);

$dashboard = new DashboardController();
$router->get('/admin', [$dashboard, 'index']);

$adminProperties = new PropertyAdminController();
$router->get('/admin/properties', [$adminProperties, 'index']);
$router->get('/admin/properties/create', [$adminProperties, 'create']);
$router->post('/admin/properties', [$adminProperties, 'store']);
$router->get('/admin/properties/{id}/edit', [$adminProperties, 'edit']);
$router->post('/admin/properties/{id}', [$adminProperties, 'update']);
$router->post('/admin/properties/{id}/delete', [$adminProperties, 'destroy']);
$router->post('/admin/properties/{id}/toggle-status', [$adminProperties, 'toggleStatus']);
$router->post('/admin/properties/{id}/toggle-featured', [$adminProperties, 'toggleFeatured']);
$router->post('/admin/properties/{id}/images/{image_id}/delete', [$adminProperties, 'deleteImage']);

$adminInquiries = new InquiryAdminController();
$router->get('/admin/inquiries', [$adminInquiries, 'index']);
$router->post('/admin/inquiries/{id}/status', [$adminInquiries, 'updateStatus']);
$router->post('/admin/inquiries/{id}/delete', [$adminInquiries, 'destroy']);

$adminReservations = new ReservationAdminController();
$router->get('/admin/reservations', [$adminReservations, 'index']);
$router->post('/admin/reservations/{id}/status', [$adminReservations, 'updateStatus']);
$router->post('/admin/reservations/{id}/delete', [$adminReservations, 'destroy']);

$adminUsers = new UserAdminController();
$router->get('/admin/users', [$adminUsers, 'index']);
$router->post('/admin/users/{id}/role', [$adminUsers, 'updateRole']);
$router->post('/admin/users/{id}/delete', [$adminUsers, 'destroy']);

$adminCategories = new CategoryAdminController();
$router->get('/admin/categories', [$adminCategories, 'index']);
$router->post('/admin/categories', [$adminCategories, 'store']);
$router->post('/admin/categories/{id}', [$adminCategories, 'update']);
$router->post('/admin/categories/{id}/delete', [$adminCategories, 'destroy']);

// ---------- Dispatch ----------
if (!$router->dispatch($request)) {
    if ($isApi) {
        Response::notFound('Route not found.');
    }
    if ($request->path === '/') {
        Response::redirect('/admin');
    }
    http_response_code(404);
    header('Content-Type: text/html; charset=utf-8');
    echo '<h1>404 Not Found</h1>';
}
