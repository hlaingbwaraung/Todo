<?php

declare(strict_types=1);

namespace App\Models;

use App\Core\Database as DB;

final class User
{
    public static function now(): string
    {
        return date('Y-m-d H:i:s');
    }

    /** Public API shape — never includes password_hash. */
    public static function shape(array $row): array
    {
        return [
            'id'         => (int)$row['id'],
            'name'       => $row['name'],
            'email'      => $row['email'],
            'phone'      => $row['phone'],
            'role'       => $row['role'],
            'avatar_url' => $row['avatar_url'],
            'created_at' => date('c', strtotime((string)$row['created_at'])),
        ];
    }

    public static function find(int $id): ?array
    {
        return DB::selectOne('SELECT * FROM users WHERE id = ?', [$id]);
    }

    public static function findByEmail(string $email): ?array
    {
        return DB::selectOne('SELECT * FROM users WHERE email = ?', [$email]);
    }

    public static function create(string $name, string $email, string $password, ?string $phone = null, string $role = 'user'): int
    {
        $now = self::now();
        DB::execute(
            'INSERT INTO users (name, email, password_hash, phone, role, avatar_url, created_at, updated_at)
             VALUES (?, ?, ?, ?, ?, NULL, ?, ?)',
            [$name, $email, password_hash($password, PASSWORD_DEFAULT), $phone, $role, $now, $now]
        );
        return DB::lastInsertId();
    }

    public static function update(int $id, array $fields): void
    {
        if ($fields === []) {
            return;
        }
        $sets = [];
        $params = [];
        foreach ($fields as $col => $value) {
            $sets[] = "$col = ?";
            $params[] = $value;
        }
        $sets[] = 'updated_at = ?';
        $params[] = self::now();
        $params[] = $id;
        DB::execute('UPDATE users SET ' . implode(', ', $sets) . ' WHERE id = ?', $params);
    }

    public static function all(): array
    {
        return DB::select('SELECT * FROM users ORDER BY id ASC');
    }

    public static function delete(int $id): void
    {
        DB::execute('DELETE FROM users WHERE id = ?', [$id]);
    }

    public static function count(): int
    {
        return (int)(DB::selectOne('SELECT COUNT(*) AS c FROM users')['c'] ?? 0);
    }
}
