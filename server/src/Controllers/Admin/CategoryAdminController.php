<?php

declare(strict_types=1);

namespace App\Controllers\Admin;

use App\Core\Auth;
use App\Core\Csrf;
use App\Core\Request;
use App\Core\Response;
use App\Core\View;
use App\Models\Category;

final class CategoryAdminController
{
    public function index(Request $request): never
    {
        $admin = Auth::requireAdmin();
        $error = $request->queryParam('error');
        View::render('admin/categories', [
            'admin'      => $admin,
            'active'     => 'categories',
            'title'      => 'Categories',
            'categories' => Category::allWithCounts(false),
            'error'      => is_string($error) ? $error : null,
        ]);
    }

    public function store(Request $request): never
    {
        Auth::requireAdmin();
        Csrf::verifyOrAbort($request);

        $name = trim((string)$request->input('name', ''));
        $nameJa = trim((string)$request->input('name_ja', ''));
        $slug = strtolower(trim((string)$request->input('slug', '')));

        if ($name === '' || $nameJa === '' || !preg_match('/^[a-z0-9\-]+$/', $slug)) {
            Response::redirect('/admin/categories?error=' . rawurlencode('Name, Japanese name and a slug (a-z, 0-9, -) are required.'));
        }
        if (Category::findBySlug($slug) !== null) {
            Response::redirect('/admin/categories?error=' . rawurlencode('Slug already exists.'));
        }

        Category::create($name, $nameJa, $slug);
        Response::redirect('/admin/categories');
    }

    public function update(Request $request): never
    {
        Auth::requireAdmin();
        Csrf::verifyOrAbort($request);

        $id = (int)$request->param('id');
        $category = Category::find($id);
        if ($category === null) {
            Response::redirect('/admin/categories');
        }

        $name = trim((string)$request->input('name', ''));
        $nameJa = trim((string)$request->input('name_ja', ''));
        $slug = strtolower(trim((string)$request->input('slug', '')));

        if ($name === '' || $nameJa === '' || !preg_match('/^[a-z0-9\-]+$/', $slug)) {
            Response::redirect('/admin/categories?error=' . rawurlencode('Name, Japanese name and a slug (a-z, 0-9, -) are required.'));
        }
        $existing = Category::findBySlug($slug);
        if ($existing !== null && (int)$existing['id'] !== $id) {
            Response::redirect('/admin/categories?error=' . rawurlencode('Slug already exists.'));
        }

        Category::update($id, $name, $nameJa, $slug);
        Response::redirect('/admin/categories');
    }

    public function destroy(Request $request): never
    {
        Auth::requireAdmin();
        Csrf::verifyOrAbort($request);

        $id = (int)$request->param('id');
        if (Category::propertyCount($id) > 0) {
            Response::redirect('/admin/categories?error=' . rawurlencode('Cannot delete a category that still has properties.'));
        }
        Category::delete($id);
        Response::redirect('/admin/categories');
    }
}
