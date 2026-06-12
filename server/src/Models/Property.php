<?php

declare(strict_types=1);

namespace App\Models;

use App\Core\Database as DB;

final class Property
{
    public const LAYOUTS = ['1R', '1K', '1DK', '1LDK', '2K', '2DK', '2LDK', '3LDK', '4LDK+'];

    public const AMENITIES = [
        'autolock', 'balcony', 'air_conditioner', 'bath_toilet_separate',
        'delivery_box', 'internet_free', 'system_kitchen', 'floor_heating',
        'elevator', 'washlet', 'walk_in_closet', 'counter_kitchen',
        'reheating_bath', 'gas_stove', 'city_gas', 'concierge', 'gym', 'guest_room',
    ];

    // ---------- Serialization ----------

    /**
     * Shape a DB row into the API Property object.
     *
     * @param array      $row       property row (optionally joined with category cols c_*)
     * @param bool       $detail    include description* and images
     * @param array|null $images    pre-fetched images for this property (detail)
     * @param string|null $thumb    pre-fetched thumbnail url (list)
     * @param bool|null  $isFavorite null = unauthenticated (omit-as-false per spec we still include only when auth)
     */
    public static function shape(
        array $row,
        bool $detail = false,
        ?array $images = null,
        ?string $thumb = null,
        ?bool $isFavorite = null
    ): array {
        $amenities = [];
        if (!empty($row['amenities'])) {
            $decoded = json_decode((string)$row['amenities'], true);
            if (is_array($decoded)) {
                $amenities = array_values($decoded);
            }
        }

        $category = null;
        if (!empty($row['category_id'])) {
            if (isset($row['c_id']) && $row['c_id'] !== null) {
                $category = [
                    'id'      => (int)$row['c_id'],
                    'name'    => $row['c_name'],
                    'name_ja' => $row['c_name_ja'],
                    'slug'    => $row['c_slug'],
                ];
            } else {
                $cat = Category::find((int)$row['category_id']);
                if ($cat !== null) {
                    $category = Category::shape($cat);
                }
            }
        }

        $builtYear = $row['built_year'] !== null ? (int)$row['built_year'] : null;

        $shaped = [
            'id'                 => (int)$row['id'],
            'title'              => $row['title'],
            'title_ja'           => $row['title_ja'],
            'transaction_type'   => $row['transaction_type'],
            'status'             => $row['status'],
            'is_featured'        => (bool)$row['is_featured'],
            'price'              => (int)$row['price'],
            'management_fee'     => $row['management_fee'] !== null ? (int)$row['management_fee'] : null,
            'deposit_months'     => $row['deposit_months'] !== null ? (float)$row['deposit_months'] : null,
            'key_money_months'   => $row['key_money_months'] !== null ? (float)$row['key_money_months'] : null,
            'address'            => $row['address'],
            'address_ja'         => $row['address_ja'],
            'prefecture'         => $row['prefecture'],
            'city'               => $row['city'],
            'latitude'           => $row['latitude'] !== null ? (float)$row['latitude'] : null,
            'longitude'          => $row['longitude'] !== null ? (float)$row['longitude'] : null,
            'nearest_station'    => $row['nearest_station'],
            'nearest_station_ja' => $row['nearest_station_ja'],
            'station_walk_min'   => $row['station_walk_min'] !== null ? (int)$row['station_walk_min'] : null,
            'layout'             => $row['layout'],
            'size_sqm'           => $row['size_sqm'] !== null ? (float)$row['size_sqm'] : null,
            'built_year'         => $builtYear,
            'building_age_years' => $builtYear !== null ? max(0, (int)date('Y') - $builtYear) : null,
            'floor'              => $row['floor'] !== null ? (int)$row['floor'] : null,
            'total_floors'       => $row['total_floors'] !== null ? (int)$row['total_floors'] : null,
            'category_id'        => $row['category_id'] !== null ? (int)$row['category_id'] : null,
            'category'           => $category,
            'pet_allowed'        => (bool)$row['pet_allowed'],
            'parking_available'  => (bool)$row['parking_available'],
            'amenities'          => $amenities,
            'floor_plan_url'     => self::absoluteUrl($row['floor_plan_url']),
            'agent_name'         => $row['agent_name'],
            'agent_company'      => $row['agent_company'],
            'agent_phone'        => $row['agent_phone'],
            'agent_email'        => $row['agent_email'],
            'view_count'         => (int)$row['view_count'],
            'created_at'         => date('c', strtotime((string)$row['created_at'])),
            'updated_at'         => date('c', strtotime((string)$row['updated_at'])),
        ];

        if ($detail) {
            $shaped['description'] = $row['description'];
            $shaped['description_ja'] = $row['description_ja'];
            $images ??= self::images((int)$row['id']);
            $shaped['images'] = array_map(static fn(array $img) => [
                'id'         => (int)$img['id'],
                'url'        => self::absoluteUrl($img['url']),
                'sort_order' => (int)$img['sort_order'],
            ], $images);
            $shaped['thumbnail_url'] = self::absoluteUrl($images[0]['url'] ?? null);
        } else {
            $shaped['thumbnail_url'] = self::absoluteUrl($thumb);
        }

        if ($isFavorite !== null) {
            $shaped['is_favorite'] = $isFavorite;
        }

        return $shaped;
    }

    /**
     * Shape a list of rows (list shape) with batched thumbnails / favorite flags.
     */
    public static function shapeList(array $rows, ?int $userId): array
    {
        if ($rows === []) {
            return [];
        }
        $ids = array_map(static fn(array $r) => (int)$r['id'], $rows);
        $thumbs = self::thumbnails($ids);
        $favorites = $userId !== null ? self::favoriteSet($userId, $ids) : [];

        $out = [];
        foreach ($rows as $row) {
            $id = (int)$row['id'];
            $out[] = self::shape(
                $row,
                false,
                null,
                $thumbs[$id] ?? null,
                $userId !== null ? isset($favorites[$id]) : null
            );
        }
        return $out;
    }

    // ---------- Queries ----------

    private const SELECT = 'SELECT p.*, c.id AS c_id, c.name AS c_name, c.name_ja AS c_name_ja, c.slug AS c_slug
        FROM properties p LEFT JOIN categories c ON c.id = p.category_id';

    public static function find(int $id): ?array
    {
        return DB::selectOne(self::SELECT . ' WHERE p.id = ?', [$id]);
    }

    public static function findPublished(int $id): ?array
    {
        return DB::selectOne(self::SELECT . " WHERE p.id = ? AND p.status = 'published'", [$id]);
    }

    public static function images(int $propertyId): array
    {
        return DB::select(
            'SELECT * FROM property_images WHERE property_id = ? ORDER BY sort_order ASC, id ASC',
            [$propertyId]
        );
    }

    /** @return array<int,string> property_id => first image url */
    public static function thumbnails(array $propertyIds): array
    {
        if ($propertyIds === []) {
            return [];
        }
        $placeholders = implode(',', array_fill(0, count($propertyIds), '?'));
        $rows = DB::select(
            "SELECT property_id, url, sort_order, id FROM property_images
             WHERE property_id IN ($placeholders)
             ORDER BY property_id, sort_order ASC, id ASC",
            array_values($propertyIds)
        );
        $thumbs = [];
        foreach ($rows as $row) {
            $pid = (int)$row['property_id'];
            if (!isset($thumbs[$pid])) {
                $thumbs[$pid] = $row['url'];
            }
        }
        return $thumbs;
    }

    /**
     * Locally uploaded images are stored root-relative ("/uploads/x.jpg");
     * API clients need a scheme+host, so resolve against APP_URL.
     */
    private static function absoluteUrl(?string $url): ?string
    {
        if ($url === null || !str_starts_with($url, '/')) {
            return $url;
        }
        static $base = null;
        if ($base === null) {
            $config = require dirname(__DIR__, 2) . '/config.php';
            $base = rtrim((string)$config['app']['url'], '/');
        }
        return $base . $url;
    }

    /** @return array<int,true> set of favorited property ids */
    public static function favoriteSet(int $userId, array $propertyIds): array
    {
        if ($propertyIds === []) {
            return [];
        }
        $placeholders = implode(',', array_fill(0, count($propertyIds), '?'));
        $rows = DB::select(
            "SELECT property_id FROM favorites WHERE user_id = ? AND property_id IN ($placeholders)",
            array_merge([$userId], array_values($propertyIds))
        );
        $set = [];
        foreach ($rows as $row) {
            $set[(int)$row['property_id']] = true;
        }
        return $set;
    }

    /**
     * Build WHERE clause + params from API filters.
     * @return array{0:string,1:array}
     */
    private static function buildFilters(array $filters, bool $publishedOnly): array
    {
        $where = [];
        $params = [];

        if ($publishedOnly) {
            $where[] = "p.status = 'published'";
        } elseif (!empty($filters['status']) && in_array($filters['status'], ['published', 'draft'], true)) {
            $where[] = 'p.status = ?';
            $params[] = $filters['status'];
        }

        if (isset($filters['q']) && $filters['q'] !== '') {
            $like = '%' . str_replace(['%', '_'], ['\\%', '\\_'], (string)$filters['q']) . '%';
            $where[] = '(p.title LIKE ? OR p.title_ja LIKE ? OR p.address LIKE ? OR p.address_ja LIKE ?
                         OR p.nearest_station LIKE ? OR p.nearest_station_ja LIKE ?)';
            array_push($params, $like, $like, $like, $like, $like, $like);
        }

        if (!empty($filters['transaction_type']) && in_array($filters['transaction_type'], ['rent', 'buy'], true)) {
            $where[] = 'p.transaction_type = ?';
            $params[] = $filters['transaction_type'];
        }

        if (isset($filters['min_price']) && is_numeric($filters['min_price'])) {
            $where[] = 'p.price >= ?';
            $params[] = (int)$filters['min_price'];
        }
        if (isset($filters['max_price']) && is_numeric($filters['max_price'])) {
            $where[] = 'p.price <= ?';
            $params[] = (int)$filters['max_price'];
        }

        if (!empty($filters['layout'])) {
            $layouts = array_values(array_filter(array_map('trim', explode(',', (string)$filters['layout']))));
            if ($layouts !== []) {
                $placeholders = implode(',', array_fill(0, count($layouts), '?'));
                $where[] = "p.layout IN ($placeholders)";
                array_push($params, ...$layouts);
            }
        }

        if (isset($filters['min_size']) && is_numeric($filters['min_size'])) {
            $where[] = 'p.size_sqm >= ?';
            $params[] = (float)$filters['min_size'];
        }
        if (isset($filters['max_size']) && is_numeric($filters['max_size'])) {
            $where[] = 'p.size_sqm <= ?';
            $params[] = (float)$filters['max_size'];
        }

        if (isset($filters['max_age']) && is_numeric($filters['max_age'])) {
            $where[] = 'p.built_year >= ?';
            $params[] = (int)date('Y') - (int)$filters['max_age'];
        }

        if (isset($filters['station']) && $filters['station'] !== '') {
            $like = '%' . str_replace(['%', '_'], ['\\%', '\\_'], (string)$filters['station']) . '%';
            $where[] = '(p.nearest_station LIKE ? OR p.nearest_station_ja LIKE ?)';
            array_push($params, $like, $like);
        }

        if (isset($filters['max_walk_min']) && is_numeric($filters['max_walk_min'])) {
            $where[] = 'p.station_walk_min <= ?';
            $params[] = (int)$filters['max_walk_min'];
        }

        if (!empty($filters['pet_allowed'])) {
            $where[] = 'p.pet_allowed = 1';
        }
        if (!empty($filters['parking'])) {
            $where[] = 'p.parking_available = 1';
        }
        if (!empty($filters['featured'])) {
            $where[] = 'p.is_featured = 1';
        }

        if (isset($filters['category']) && $filters['category'] !== '') {
            $cat = (string)$filters['category'];
            if (ctype_digit($cat)) {
                $where[] = 'p.category_id = ?';
                $params[] = (int)$cat;
            } else {
                $where[] = 'c.slug = ?';
                $params[] = $cat;
            }
        }

        $clause = $where === [] ? '' : ' WHERE ' . implode(' AND ', $where);
        return [$clause, $params];
    }

    private static function orderBy(?string $sort): string
    {
        return match ($sort) {
            'price_asc'  => ' ORDER BY p.price ASC, p.id ASC',
            'price_desc' => ' ORDER BY p.price DESC, p.id ASC',
            'size_desc'  => ' ORDER BY p.size_sqm DESC, p.id ASC',
            default      => ' ORDER BY p.created_at DESC, p.id DESC', // newest
        };
    }

    /**
     * Search with filters + pagination.
     * @return array{rows:array,meta:array}
     */
    public static function search(array $filters, bool $publishedOnly = true): array
    {
        [$whereClause, $params] = self::buildFilters($filters, $publishedOnly);

        $page = max(1, (int)($filters['page'] ?? 1));
        $perPage = (int)($filters['per_page'] ?? 20);
        if ($perPage < 1) {
            $perPage = 20;
        }
        $perPage = min($perPage, 50);

        $total = (int)(DB::selectOne(
            'SELECT COUNT(*) AS c FROM properties p LEFT JOIN categories c ON c.id = p.category_id' . $whereClause,
            $params
        )['c'] ?? 0);

        $offset = ($page - 1) * $perPage;
        $rows = DB::select(
            self::SELECT . $whereClause . self::orderBy($filters['sort'] ?? null) . " LIMIT $perPage OFFSET $offset",
            $params
        );

        return [
            'rows' => $rows,
            'meta' => [
                'page'        => $page,
                'per_page'    => $perPage,
                'total'       => $total,
                'total_pages' => $perPage > 0 ? (int)ceil($total / $perPage) : 0,
            ],
        ];
    }

    /**
     * Similar properties: same category OR same layout, published, exclude self,
     * ordered by closest price, max 6.
     */
    public static function similar(array $property): array
    {
        $conds = [];
        $params = [];
        if ($property['category_id'] !== null) {
            $conds[] = 'p.category_id = ?';
            $params[] = (int)$property['category_id'];
        }
        if ($property['layout'] !== null && $property['layout'] !== '') {
            $conds[] = 'p.layout = ?';
            $params[] = $property['layout'];
        }
        if ($conds === []) {
            return [];
        }
        $sql = self::SELECT . " WHERE p.status = 'published' AND p.id <> ? AND (" . implode(' OR ', $conds) . ')
            ORDER BY ABS(p.price - ?) ASC, p.id ASC LIMIT 6';
        return DB::select($sql, array_merge([(int)$property['id']], $params, [(int)$property['price']]));
    }

    public static function incrementViewCount(int $id): void
    {
        DB::execute('UPDATE properties SET view_count = view_count + 1 WHERE id = ?', [$id]);
    }

    // ---------- Mutations (admin) ----------

    public const FIELDS = [
        'title', 'title_ja', 'description', 'description_ja', 'transaction_type', 'status',
        'is_featured', 'price', 'management_fee', 'deposit_months', 'key_money_months',
        'address', 'address_ja', 'prefecture', 'city', 'latitude', 'longitude',
        'nearest_station', 'nearest_station_ja', 'station_walk_min', 'layout', 'size_sqm',
        'built_year', 'floor', 'total_floors', 'category_id', 'pet_allowed',
        'parking_available', 'amenities', 'floor_plan_url',
        'agent_name', 'agent_company', 'agent_phone', 'agent_email',
    ];

    public static function create(array $data): int
    {
        $now = date('Y-m-d H:i:s');
        $cols = [];
        $params = [];
        foreach (self::FIELDS as $field) {
            $cols[] = $field;
            $params[] = $data[$field] ?? null;
        }
        $cols[] = 'view_count';
        $params[] = (int)($data['view_count'] ?? 0);
        $cols[] = 'created_at';
        $params[] = $data['created_at'] ?? $now;
        $cols[] = 'updated_at';
        $params[] = $now;

        $placeholders = implode(',', array_fill(0, count($cols), '?'));
        DB::execute(
            'INSERT INTO properties (' . implode(',', $cols) . ") VALUES ($placeholders)",
            $params
        );
        return DB::lastInsertId();
    }

    public static function update(int $id, array $data): void
    {
        $sets = [];
        $params = [];
        foreach (self::FIELDS as $field) {
            if (array_key_exists($field, $data)) {
                $sets[] = "$field = ?";
                $params[] = $data[$field];
            }
        }
        if ($sets === []) {
            return;
        }
        $sets[] = 'updated_at = ?';
        $params[] = date('Y-m-d H:i:s');
        $params[] = $id;
        DB::execute('UPDATE properties SET ' . implode(', ', $sets) . ' WHERE id = ?', $params);
    }

    public static function delete(int $id): void
    {
        DB::execute('DELETE FROM properties WHERE id = ?', [$id]);
    }

    public static function addImage(int $propertyId, string $url, int $sortOrder): int
    {
        DB::execute(
            'INSERT INTO property_images (property_id, url, sort_order, created_at) VALUES (?, ?, ?, ?)',
            [$propertyId, $url, $sortOrder, date('Y-m-d H:i:s')]
        );
        return DB::lastInsertId();
    }

    public static function deleteImage(int $imageId, int $propertyId): ?array
    {
        $img = DB::selectOne('SELECT * FROM property_images WHERE id = ? AND property_id = ?', [$imageId, $propertyId]);
        if ($img !== null) {
            DB::execute('DELETE FROM property_images WHERE id = ?', [$imageId]);
        }
        return $img;
    }

    public static function updateImageOrder(int $imageId, int $propertyId, int $sortOrder): void
    {
        DB::execute(
            'UPDATE property_images SET sort_order = ? WHERE id = ? AND property_id = ?',
            [$sortOrder, $imageId, $propertyId]
        );
    }
}
