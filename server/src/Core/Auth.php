<?php

declare(strict_types=1);

namespace App\Core;

use App\Models\User;

final class Auth
{
    public static function secret(): string
    {
        $config = require dirname(__DIR__, 2) . '/config.php';
        return (string)$config['app']['key'];
    }

    public static function issueToken(int $userId): string
    {
        return Jwt::encode(['sub' => $userId], self::secret());
    }

    /**
     * Resolve the bearer token to a user row (no password_hash). Null if absent/invalid.
     */
    public static function userFromRequest(Request $request): ?array
    {
        $token = $request->bearerToken();
        if ($token === null) {
            return null;
        }
        $claims = Jwt::decode($token, self::secret());
        if ($claims === null || !isset($claims['sub'])) {
            return null;
        }
        return User::find((int)$claims['sub']);
    }

    /**
     * Optional auth: attaches user if a valid token is present.
     */
    public static function optional(Request $request): void
    {
        $request->user = self::userFromRequest($request);
    }

    /**
     * Required auth: 401 if no valid token.
     */
    public static function require(Request $request): array
    {
        $user = self::userFromRequest($request);
        if ($user === null) {
            Response::unauthorized();
        }
        $request->user = $user;
        return $user;
    }

    // ----- Admin session auth -----

    public static function startSession(): void
    {
        if (session_status() !== PHP_SESSION_ACTIVE) {
            session_name('happyhome_admin');
            session_start([
                'cookie_httponly' => true,
                'cookie_samesite' => 'Lax',
            ]);
        }
    }

    public static function adminUser(): ?array
    {
        self::startSession();
        $id = $_SESSION['admin_user_id'] ?? null;
        if ($id === null) {
            return null;
        }
        $user = User::find((int)$id);
        if ($user === null || $user['role'] !== 'admin') {
            return null;
        }
        return $user;
    }

    public static function requireAdmin(): array
    {
        $user = self::adminUser();
        if ($user === null) {
            Response::redirect('/admin/login');
        }
        return $user;
    }

    public static function loginAdmin(int $userId): void
    {
        self::startSession();
        session_regenerate_id(true);
        $_SESSION['admin_user_id'] = $userId;
    }

    public static function logoutAdmin(): void
    {
        self::startSession();
        $_SESSION = [];
        session_destroy();
    }
}
