<?php

declare(strict_types=1);

namespace App\Models;

use App\Core\Database as DB;

final class Favorite
{
    public static function exists(int $userId, int $propertyId): bool
    {
        return DB::selectOne(
            'SELECT id FROM favorites WHERE user_id = ? AND property_id = ?',
            [$userId, $propertyId]
        ) !== null;
    }

    public static function add(int $userId, int $propertyId): void
    {
        DB::execute(
            'INSERT INTO favorites (user_id, property_id, created_at) VALUES (?, ?, ?)',
            [$userId, $propertyId, date('Y-m-d H:i:s')]
        );
    }

    public static function remove(int $userId, int $propertyId): int
    {
        return DB::execute(
            'DELETE FROM favorites WHERE user_id = ? AND property_id = ?',
            [$userId, $propertyId]
        );
    }

    /** Published properties favorited by the user, newest favorite first. */
    public static function propertiesFor(int $userId): array
    {
        return DB::select(
            "SELECT p.*, c.id AS c_id, c.name AS c_name, c.name_ja AS c_name_ja, c.slug AS c_slug
             FROM favorites f
             JOIN properties p ON p.id = f.property_id
             LEFT JOIN categories c ON c.id = p.category_id
             WHERE f.user_id = ? AND p.status = 'published'
             ORDER BY f.created_at DESC, f.id DESC",
            [$userId]
        );
    }
}
