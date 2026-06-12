<?php

declare(strict_types=1);

namespace App\Models;

use App\Core\Database as DB;

final class Category
{
    public static function shape(array $row): array
    {
        $shaped = [
            'id'      => (int)$row['id'],
            'name'    => $row['name'],
            'name_ja' => $row['name_ja'],
            'slug'    => $row['slug'],
        ];
        if (array_key_exists('property_count', $row)) {
            $shaped['property_count'] = (int)$row['property_count'];
        }
        return $shaped;
    }

    public static function find(int $id): ?array
    {
        return DB::selectOne('SELECT * FROM categories WHERE id = ?', [$id]);
    }

    public static function findBySlug(string $slug): ?array
    {
        return DB::selectOne('SELECT * FROM categories WHERE slug = ?', [$slug]);
    }

    /** All categories with published-property counts (API). */
    public static function allWithCounts(bool $publishedOnly = true): array
    {
        $cond = $publishedOnly ? "AND p.status = 'published'" : '';
        return DB::select(
            "SELECT c.*, (
                SELECT COUNT(*) FROM properties p
                WHERE p.category_id = c.id $cond
             ) AS property_count
             FROM categories c
             ORDER BY c.id ASC"
        );
    }

    public static function all(): array
    {
        return DB::select('SELECT * FROM categories ORDER BY id ASC');
    }

    public static function create(string $name, string $nameJa, string $slug): int
    {
        $now = date('Y-m-d H:i:s');
        DB::execute(
            'INSERT INTO categories (name, name_ja, slug, created_at, updated_at) VALUES (?, ?, ?, ?, ?)',
            [$name, $nameJa, $slug, $now, $now]
        );
        return DB::lastInsertId();
    }

    public static function update(int $id, string $name, string $nameJa, string $slug): void
    {
        DB::execute(
            'UPDATE categories SET name = ?, name_ja = ?, slug = ?, updated_at = ? WHERE id = ?',
            [$name, $nameJa, $slug, date('Y-m-d H:i:s'), $id]
        );
    }

    public static function delete(int $id): void
    {
        DB::execute('DELETE FROM categories WHERE id = ?', [$id]);
    }

    public static function propertyCount(int $id): int
    {
        return (int)(DB::selectOne(
            'SELECT COUNT(*) AS c FROM properties WHERE category_id = ?',
            [$id]
        )['c'] ?? 0);
    }
}
