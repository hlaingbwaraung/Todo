<?php

declare(strict_types=1);

namespace App\Core;

/**
 * Minimal hand-rolled JWT (HS256 only).
 */
final class Jwt
{
    public static function base64UrlEncode(string $data): string
    {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    public static function base64UrlDecode(string $data): string|false
    {
        $remainder = strlen($data) % 4;
        if ($remainder) {
            $data .= str_repeat('=', 4 - $remainder);
        }
        return base64_decode(strtr($data, '-_', '+/'), true);
    }

    public static function encode(array $claims, string $secret, ?int $ttl = null): string
    {
        $config = require dirname(__DIR__, 2) . '/config.php';
        $ttl ??= (int)$config['jwt']['ttl'];

        $header = ['typ' => 'JWT', 'alg' => 'HS256'];
        $now = time();
        $claims = array_merge(['iat' => $now, 'exp' => $now + $ttl], $claims);

        $segments = [
            self::base64UrlEncode(json_encode($header, JSON_UNESCAPED_SLASHES)),
            self::base64UrlEncode(json_encode($claims, JSON_UNESCAPED_SLASHES)),
        ];
        $signingInput = implode('.', $segments);
        $signature = hash_hmac('sha256', $signingInput, $secret, true);
        $segments[] = self::base64UrlEncode($signature);

        return implode('.', $segments);
    }

    /**
     * Returns decoded claims array, or null if invalid/expired.
     */
    public static function decode(string $token, string $secret): ?array
    {
        $parts = explode('.', $token);
        if (count($parts) !== 3) {
            return null;
        }
        [$headB64, $claimsB64, $sigB64] = $parts;

        $headerJson = self::base64UrlDecode($headB64);
        $claimsJson = self::base64UrlDecode($claimsB64);
        $signature = self::base64UrlDecode($sigB64);
        if ($headerJson === false || $claimsJson === false || $signature === false) {
            return null;
        }

        $header = json_decode($headerJson, true);
        if (!is_array($header) || ($header['alg'] ?? '') !== 'HS256') {
            return null;
        }

        $expected = hash_hmac('sha256', $headB64 . '.' . $claimsB64, $secret, true);
        if (!hash_equals($expected, $signature)) {
            return null;
        }

        $claims = json_decode($claimsJson, true);
        if (!is_array($claims)) {
            return null;
        }
        if (isset($claims['exp']) && time() >= (int)$claims['exp']) {
            return null;
        }
        return $claims;
    }
}
