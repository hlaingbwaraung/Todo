<?php

declare(strict_types=1);

namespace App\Core;

final class Csrf
{
    public static function token(): string
    {
        Auth::startSession();
        if (empty($_SESSION['csrf_token'])) {
            $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
        }
        return $_SESSION['csrf_token'];
    }

    public static function field(): string
    {
        return '<input type="hidden" name="_csrf" value="' .
            htmlspecialchars(self::token(), ENT_QUOTES, 'UTF-8') . '">';
    }

    public static function validate(?string $token): bool
    {
        Auth::startSession();
        $expected = $_SESSION['csrf_token'] ?? null;
        return is_string($expected) && is_string($token) && $token !== '' && hash_equals($expected, $token);
    }

    /**
     * Abort with 403 if the request's CSRF token is missing/invalid.
     */
    public static function verifyOrAbort(Request $request): void
    {
        $token = $request->input('_csrf');
        if (!self::validate(is_string($token) ? $token : null)) {
            http_response_code(403);
            header('Content-Type: text/html; charset=utf-8');
            echo '<h1>403 Forbidden</h1><p>Invalid CSRF token.</p>';
            exit;
        }
    }
}
