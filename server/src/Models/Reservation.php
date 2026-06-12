<?php

declare(strict_types=1);

namespace App\Models;

use App\Core\Database as DB;

final class Reservation
{
    public const STATUSES = ['pending', 'confirmed', 'cancelled', 'completed'];

    public static function shape(array $row): array
    {
        $shaped = [
            'id'             => (int)$row['id'],
            'property_id'    => (int)$row['property_id'],
            'user_id'        => $row['user_id'] !== null ? (int)$row['user_id'] : null,
            'name'           => $row['name'],
            'email'          => $row['email'],
            'phone'          => $row['phone'],
            'preferred_date' => $row['preferred_date'],
            'preferred_time' => $row['preferred_time'],
            'message'        => $row['message'],
            'status'         => $row['status'],
            'created_at'     => date('c', strtotime((string)$row['created_at'])),
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
            'INSERT INTO reservations (property_id, user_id, name, email, phone, preferred_date, preferred_time, message, status, created_at, updated_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            [
                $data['property_id'], $data['user_id'], $data['name'], $data['email'], $data['phone'],
                $data['preferred_date'], $data['preferred_time'], $data['message'], 'pending',
                $data['created_at'] ?? $now, $now,
            ]
        );
        return DB::lastInsertId();
    }

    public static function find(int $id): ?array
    {
        return DB::selectOne('SELECT * FROM reservations WHERE id = ?', [$id]);
    }

    public static function forUser(int $userId): array
    {
        return DB::select(
            'SELECT r.*, p.title AS property_title, p.title_ja AS property_title_ja,
                    (SELECT url FROM property_images pi WHERE pi.property_id = p.id
                     ORDER BY pi.sort_order ASC, pi.id ASC LIMIT 1) AS property_thumbnail
             FROM reservations r
             JOIN properties p ON p.id = r.property_id
             WHERE r.user_id = ?
             ORDER BY r.created_at DESC, r.id DESC',
            [$userId]
        );
    }

    public static function allWithProperty(): array
    {
        return DB::select(
            'SELECT r.*, p.title AS property_title, p.title_ja AS property_title_ja
             FROM reservations r
             JOIN properties p ON p.id = r.property_id
             ORDER BY r.created_at DESC, r.id DESC'
        );
    }

    public static function recent(int $limit = 5): array
    {
        return DB::select(
            'SELECT r.*, p.title AS property_title, p.title_ja AS property_title_ja
             FROM reservations r
             JOIN properties p ON p.id = r.property_id
             ORDER BY r.created_at DESC, r.id DESC
             LIMIT ' . (int)$limit
        );
    }

    public static function updateStatus(int $id, string $status): void
    {
        DB::execute(
            'UPDATE reservations SET status = ?, updated_at = ? WHERE id = ?',
            [$status, date('Y-m-d H:i:s'), $id]
        );
    }

    public static function delete(int $id): void
    {
        DB::execute('DELETE FROM reservations WHERE id = ?', [$id]);
    }

    public static function countByStatus(string $status): int
    {
        return (int)(DB::selectOne(
            'SELECT COUNT(*) AS c FROM reservations WHERE status = ?',
            [$status]
        )['c'] ?? 0);
    }
}
