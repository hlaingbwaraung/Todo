<?php

declare(strict_types=1);

namespace App\Models;

use App\Core\Database as DB;

final class Device
{
    /** Upsert per user+token. Returns the device row. */
    public static function upsert(int $userId, string $deviceToken, string $platform): array
    {
        $now = date('Y-m-d H:i:s');
        $existing = DB::selectOne(
            'SELECT * FROM devices WHERE user_id = ? AND device_token = ?',
            [$userId, $deviceToken]
        );
        if ($existing !== null) {
            DB::execute(
                'UPDATE devices SET platform = ?, updated_at = ? WHERE id = ?',
                [$platform, $now, (int)$existing['id']]
            );
        } else {
            DB::execute(
                'INSERT INTO devices (user_id, device_token, platform, created_at, updated_at)
                 VALUES (?, ?, ?, ?, ?)',
                [$userId, $deviceToken, $platform, $now, $now]
            );
        }
        return DB::selectOne(
            'SELECT * FROM devices WHERE user_id = ? AND device_token = ?',
            [$userId, $deviceToken]
        );
    }

    public static function shape(array $row): array
    {
        return [
            'id'           => (int)$row['id'],
            'user_id'      => (int)$row['user_id'],
            'device_token' => $row['device_token'],
            'platform'     => $row['platform'],
            'created_at'   => date('c', strtotime((string)$row['created_at'])),
        ];
    }
}
