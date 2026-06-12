<?php

declare(strict_types=1);

namespace App\Controllers\Admin;

use App\Core\Auth;
use App\Core\Csrf;
use App\Core\Request;
use App\Core\Response;
use App\Core\View;
use App\Models\Category;
use App\Models\Property;

final class PropertyAdminController
{
    public function index(Request $request): never
    {
        $admin = Auth::requireAdmin();

        $filters = [
            'q'                => $request->queryParam('q', ''),
            'status'           => $request->queryParam('status', ''),
            'transaction_type' => $request->queryParam('type', ''),
            'category'         => $request->queryParam('category', ''),
            'page'             => $request->queryParam('page', 1),
            'per_page'         => 15,
            'sort'             => 'newest',
        ];
        $result = Property::search($filters, false);
        $thumbs = Property::thumbnails(array_map(static fn($r) => (int)$r['id'], $result['rows']));

        View::render('admin/properties/index', [
            'admin'      => $admin,
            'active'     => 'properties',
            'title'      => 'Properties',
            'rows'       => $result['rows'],
            'meta'       => $result['meta'],
            'thumbs'     => $thumbs,
            'filters'    => $filters,
            'categories' => Category::all(),
        ]);
    }

    public function create(Request $request): never
    {
        $admin = Auth::requireAdmin();
        View::render('admin/properties/form', [
            'admin'      => $admin,
            'active'     => 'properties',
            'title'      => 'New Property',
            'property'   => null,
            'images'     => [],
            'categories' => Category::all(),
            'errors'     => [],
            'old'        => [],
        ]);
    }

    public function store(Request $request): never
    {
        $admin = Auth::requireAdmin();
        Csrf::verifyOrAbort($request);

        [$data, $errors] = $this->collectAndValidate($request);
        if ($errors !== []) {
            View::render('admin/properties/form', [
                'admin'      => $admin,
                'active'     => 'properties',
                'title'      => 'New Property',
                'property'   => null,
                'images'     => [],
                'categories' => Category::all(),
                'errors'     => $errors,
                'old'        => $request->body,
            ]);
        }

        $id = Property::create($data);
        $this->handleImages($request, $id);
        Response::redirect('/admin/properties/' . $id . '/edit');
    }

    public function edit(Request $request): never
    {
        $admin = Auth::requireAdmin();
        $id = (int)$request->param('id');
        $property = Property::find($id);
        if ($property === null) {
            Response::redirect('/admin/properties');
        }

        View::render('admin/properties/form', [
            'admin'      => $admin,
            'active'     => 'properties',
            'title'      => 'Edit Property #' . $id,
            'property'   => $property,
            'images'     => Property::images($id),
            'categories' => Category::all(),
            'errors'     => [],
            'old'        => [],
        ]);
    }

    public function update(Request $request): never
    {
        $admin = Auth::requireAdmin();
        Csrf::verifyOrAbort($request);

        $id = (int)$request->param('id');
        $property = Property::find($id);
        if ($property === null) {
            Response::redirect('/admin/properties');
        }

        [$data, $errors] = $this->collectAndValidate($request);
        if ($errors !== []) {
            View::render('admin/properties/form', [
                'admin'      => $admin,
                'active'     => 'properties',
                'title'      => 'Edit Property #' . $id,
                'property'   => $property,
                'images'     => Property::images($id),
                'categories' => Category::all(),
                'errors'     => $errors,
                'old'        => $request->body,
            ]);
        }

        Property::update($id, $data);

        // Existing image sort orders
        $orders = $request->input('image_order');
        if (is_array($orders)) {
            foreach ($orders as $imageId => $order) {
                Property::updateImageOrder((int)$imageId, $id, (int)$order);
            }
        }

        $this->handleImages($request, $id);
        Response::redirect('/admin/properties/' . $id . '/edit');
    }

    public function destroy(Request $request): never
    {
        Auth::requireAdmin();
        Csrf::verifyOrAbort($request);

        $id = (int)$request->param('id');
        foreach (Property::images($id) as $img) {
            $this->deleteUploadedFile((string)$img['url']);
        }
        Property::delete($id);
        Response::redirect('/admin/properties');
    }

    public function toggleStatus(Request $request): never
    {
        Auth::requireAdmin();
        Csrf::verifyOrAbort($request);

        $id = (int)$request->param('id');
        $property = Property::find($id);
        if ($property !== null) {
            Property::update($id, [
                'status' => $property['status'] === 'published' ? 'draft' : 'published',
            ]);
        }
        $this->redirectBack($request, '/admin/properties');
    }

    public function toggleFeatured(Request $request): never
    {
        Auth::requireAdmin();
        Csrf::verifyOrAbort($request);

        $id = (int)$request->param('id');
        $property = Property::find($id);
        if ($property !== null) {
            Property::update($id, ['is_featured' => $property['is_featured'] ? 0 : 1]);
        }
        $this->redirectBack($request, '/admin/properties');
    }

    public function deleteImage(Request $request): never
    {
        Auth::requireAdmin();
        Csrf::verifyOrAbort($request);

        $propertyId = (int)$request->param('id');
        $imageId = (int)$request->param('image_id');
        $img = Property::deleteImage($imageId, $propertyId);
        if ($img !== null) {
            $this->deleteUploadedFile((string)$img['url']);
        }
        Response::redirect('/admin/properties/' . $propertyId . '/edit');
    }

    // ---------- helpers ----------

    private function redirectBack(Request $request, string $fallback): never
    {
        $ref = $_SERVER['HTTP_REFERER'] ?? '';
        $path = is_string($ref) ? (string)(parse_url($ref, PHP_URL_PATH) ?? '') : '';
        $query = is_string($ref) ? (string)(parse_url($ref, PHP_URL_QUERY) ?? '') : '';
        if (str_starts_with($path, '/admin')) {
            Response::redirect($path . ($query !== '' ? '?' . $query : ''));
        }
        Response::redirect($fallback);
    }

    /**
     * @return array{0:array,1:array} [data, errors]
     */
    private function collectAndValidate(Request $request): array
    {
        $in = fn(string $key) => $request->input($key);
        $str = function (string $key) use ($in): ?string {
            $v = $in($key);
            $v = is_string($v) ? trim($v) : $v;
            return ($v === null || $v === '') ? null : (string)$v;
        };
        $num = fn(string $key) => is_numeric($in($key)) ? $in($key) : null;

        $errors = [];
        $required = ['title', 'title_ja', 'address', 'address_ja'];
        foreach ($required as $field) {
            if ($str($field) === null) {
                $errors[$field] = ucfirst(str_replace('_', ' ', $field)) . ' is required.';
            }
        }
        if ($num('price') === null || (int)$num('price') < 0) {
            $errors['price'] = 'Price is required and must be a non-negative integer.';
        }

        $transactionType = $str('transaction_type');
        if (!in_array($transactionType, ['rent', 'buy'], true)) {
            $errors['transaction_type'] = 'Transaction type must be rent or buy.';
        }
        $status = $str('status');
        if (!in_array($status, ['published', 'draft'], true)) {
            $status = 'draft';
        }

        $categoryId = $num('category_id') !== null ? (int)$num('category_id') : null;
        if ($categoryId !== null && Category::find($categoryId) === null) {
            $categoryId = null;
        }

        $amenities = $in('amenities');
        if (!is_array($amenities)) {
            $amenities = [];
        }
        $amenities = array_values(array_intersect(array_map('strval', $amenities), Property::AMENITIES));

        $data = [
            'title'              => $str('title'),
            'title_ja'           => $str('title_ja'),
            'description'        => $str('description'),
            'description_ja'     => $str('description_ja'),
            'transaction_type'   => $transactionType ?? 'rent',
            'status'             => $status,
            'is_featured'        => $in('is_featured') ? 1 : 0,
            'price'              => $num('price') !== null ? (int)$num('price') : 0,
            'management_fee'     => $num('management_fee') !== null ? (int)$num('management_fee') : null,
            'deposit_months'     => $num('deposit_months') !== null ? (float)$num('deposit_months') : null,
            'key_money_months'   => $num('key_money_months') !== null ? (float)$num('key_money_months') : null,
            'address'            => $str('address'),
            'address_ja'         => $str('address_ja'),
            'prefecture'         => $str('prefecture'),
            'city'               => $str('city'),
            'latitude'           => $num('latitude') !== null ? (float)$num('latitude') : null,
            'longitude'          => $num('longitude') !== null ? (float)$num('longitude') : null,
            'nearest_station'    => $str('nearest_station'),
            'nearest_station_ja' => $str('nearest_station_ja'),
            'station_walk_min'   => $num('station_walk_min') !== null ? (int)$num('station_walk_min') : null,
            'layout'             => in_array($str('layout'), Property::LAYOUTS, true) ? $str('layout') : null,
            'size_sqm'           => $num('size_sqm') !== null ? (float)$num('size_sqm') : null,
            'built_year'         => $num('built_year') !== null ? (int)$num('built_year') : null,
            'floor'              => $num('floor') !== null ? (int)$num('floor') : null,
            'total_floors'       => $num('total_floors') !== null ? (int)$num('total_floors') : null,
            'category_id'        => $categoryId,
            'pet_allowed'        => $in('pet_allowed') ? 1 : 0,
            'parking_available'  => $in('parking_available') ? 1 : 0,
            'amenities'          => json_encode($amenities, JSON_UNESCAPED_UNICODE),
            'floor_plan_url'     => $str('floor_plan_url'),
            'agent_name'         => $str('agent_name'),
            'agent_company'      => $str('agent_company'),
            'agent_phone'        => $str('agent_phone'),
            'agent_email'        => $str('agent_email'),
        ];

        return [$data, $errors];
    }

    /**
     * Process multi-file uploads + image URL field for a property.
     */
    private function handleImages(Request $request, int $propertyId): void
    {
        $config = require dirname(__DIR__, 3) . '/config.php';
        $uploads = $config['uploads'];

        $existing = Property::images($propertyId);
        $nextOrder = 0;
        foreach ($existing as $img) {
            $nextOrder = max($nextOrder, (int)$img['sort_order'] + 1);
        }

        // 1) File uploads
        if (!empty($_FILES['images']) && is_array($_FILES['images']['name'] ?? null)) {
            $files = $_FILES['images'];
            $count = count($files['name']);
            for ($i = 0; $i < $count; $i++) {
                if (($files['error'][$i] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK) {
                    continue;
                }
                $tmp = $files['tmp_name'][$i];
                if (!is_uploaded_file($tmp)) {
                    continue;
                }
                if (($files['size'][$i] ?? 0) > $uploads['max_bytes']) {
                    continue; // over 8 MB
                }
                $mime = mime_content_type($tmp) ?: '';
                if (!isset($uploads['mime_ext'][$mime])) {
                    continue; // only jpg/png/webp
                }
                $ext = $uploads['mime_ext'][$mime];
                $name = bin2hex(random_bytes(16)) . '.' . $ext;
                if (!is_dir($uploads['dir'])) {
                    mkdir($uploads['dir'], 0775, true);
                }
                if (move_uploaded_file($tmp, $uploads['dir'] . '/' . $name)) {
                    Property::addImage($propertyId, $uploads['url_prefix'] . '/' . $name, $nextOrder++);
                }
            }
        }

        // 2) Image URLs (textarea/input, one per line)
        $urlsRaw = (string)$request->input('image_urls', '');
        foreach (preg_split('/[\r\n]+/', $urlsRaw) ?: [] as $url) {
            $url = trim($url);
            if ($url === '') {
                continue;
            }
            if (filter_var($url, FILTER_VALIDATE_URL) && preg_match('#^https?://#i', $url)) {
                Property::addImage($propertyId, $url, $nextOrder++);
            }
        }
    }

    private function deleteUploadedFile(string $url): void
    {
        $config = require dirname(__DIR__, 3) . '/config.php';
        $prefix = $config['uploads']['url_prefix'] . '/';
        if (str_starts_with($url, $prefix)) {
            $file = $config['uploads']['dir'] . '/' . basename($url);
            if (is_file($file)) {
                unlink($file);
            }
        }
    }
}
