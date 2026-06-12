<?php

declare(strict_types=1);

namespace App\Models;

use App\Core\Database as DB;

final class Inquiry
{
    public static function shape(array $row): array
    {
        $shaped = [
            'id'          => (int)$row['id'],
            'property_id' => (int)$row['property_id'],
            'user_id'     => $row['user_id'] !== null ? (int)$row['user_id'] : null,
            'name'        => $row['name'],
            'email'       => $row['email'],
            'phone'       => $row['phone'],
            'message'     => $row['message'],
            'status'      => $row['status'],
            'created_at'  => date('c', strtotime((string)$row['created_at'])),
        ];
        if (array_key_exists('property_title', $row)) {
            $shaped['property'] = [
                'id'            => (int)$row['property_id'],
                'title'         => $row['property_title'],
                'title_ja'      => $row['property_title_ja'],
                'thumbnail_url' => $row['property_thumbnail'] ?? null,
            ];
        }
        return $shaped;
    }

    public static function create(array $data): int
    {
        $now = date('Y-m-d H:i:s');
        DB::execute(
            'INSERT INTO inquiries (property_id, user_id, name, email, phone, message, status, created_at, updated_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
            [
                $data['property_id'], $data['user_id'], $data['name'], $data['email'],
                $data['phone'], $data['message'], 'new',
                $data['created_at'] ?? $now, $now,
            ]
        );
        return DB::lastInsertId();
    }

    public static function find(int $id): ?array
    {
        return DB::selectOne('SELECT * FROM inquiries WHERE id = ?', [$id]);
    }

    public static function forUser(int $userId): array
    {
        return DB::select(
            'SELECT i.*, p.title AS property_title, p.title_ja AS property_title_ja,
                    (SELECT url FROM property_images pi WHERE pi.property_id = p.id
                     ORDER BY pi.sort_order ASC, pi.id ASC LIMIT 1) AS property_thumbnail
             FROM inquiries i
             JOIN properties p ON p.id = i.property_id
             WHERE i.user_id = ?
             ORDER BY i.created_at DESC, i.id DESC',
            [$userId]
        );
    }

    public static function allWithProperty(): array
    {
        return DB::select(
            'SELECT i.*, p.title AS property_title, p.title_ja AS property_title_ja
             FROM inquiries i
             JOIN properties p ON p.id = i.property_id
             ORDER BY i.created_at DESC, i.id DESC'
        );
    }

    public static function recent(int $limit = 5): array
    {
        return DB::select(
            'SELECT i.*, p.title AS property_title, p.title_ja AS property_title_ja
             FROM inquiries i
             JOIN properties p ON p.id = i.property_id
             ORDER BY i.created_at DESC, i.id DESC
             LIMIT ' . (int)$limit
        );
    }

    public static function updateStatus(int $id, string $status): void
    {
        DB::execute(
            'UPDATE inquiries SET status = ?, updated_at = ? WHERE id = ?',
            [$status, date('Y-m-d H:i:s'), $id]
        );
    }

    public static function delete(int $id): void
    {
        DB::execute('DELETE FROM inquiries WHERE id = ?', [$id]);
    }

    public static function countByStatus(string $status): int
    {
        return (int)(DB::selectOne(
            'SELECT COUNT(*) AS c FROM inquiries WHERE status = ?',
            [$status]
        )['c'] ?? 0);
    }

    /** Inquiry counts per day for the last N days (inclusive of today). */
    public static function perDay(int $days = 7): array
    {
        $start = date('Y-m-d', strtotime('-' . ($days - 1) . ' days'));
        $rows = DB::select(
            "SELECT SUBSTR(created_at, 1, 10) AS day, COUNT(*) AS c
             FROM inquiries
             WHERE created_at >= ?
             GROUP BY SUBSTR(created_at, 1, 10)",
            [$start . ' 00:00:00']
        );
        $byDay = [];
        foreach ($rows as $row) {
            $byDay[$row['day']] = (int)$row['c'];
        }
        $out = [];
        for ($i = $days - 1; $i >= 0; $i--) {
            $day = date('Y-m-d', strtotime("-$i days"));
            $out[] = ['day' => $day, 'count' => $byDay[$day] ?? 0];
        }
        return $out;
    }
}
