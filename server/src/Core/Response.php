<?php

declare(strict_types=1);

namespace App\Core;

final class Response
{
    public static function json(mixed $payload, int $status = 200): never
    {
        http_response_code($status);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }

    public static function data(mixed $data, int $status = 200, ?array $meta = null): never
    {
        $payload = ['data' => $data];
        if ($meta !== null) {
            $payload['meta'] = $meta;
        }
        self::json($payload, $status);
    }

    public static function error(string $code, string $message, int $status, ?array $fields = null): never
    {
        $error = ['code' => $code, 'message' => $message];
        if ($fields !== null) {
            $error['fields'] = $fields;
        }
        self::json(['error' => $error], $status);
    }

    public static function validationError(array $fields, string $message = ''): never
    {
        if ($message === '') {
            $message = (string)reset($fields);
        }
        self::error('validation_error', $message, 400, $fields);
    }

    public static function unauthorized(string $message = 'Authentication required.'): never
    {
        self::error('unauthorized', $message, 401);
    }

    public static function forbidden(string $message = 'Forbidden.'): never
    {
        self::error('forbidden', $message, 403);
    }

    public static function notFound(string $message = 'Resource not found.'): never
    {
        self::error('not_found', $message, 404);
    }

    public static function redirect(string $to, int $status = 302): never
    {
        http_response_code($status);
        header('Location: ' . $to);
        exit;
    }
}
