<?php

declare(strict_types=1);

namespace App\Controllers\Admin;

use App\Core\Auth;
use App\Core\Csrf;
use App\Core\Request;
use App\Core\Response;
use App\Core\View;
use App\Models\User;

final class UserAdminController
{
    public function index(Request $request): never
    {
        $admin = Auth::requireAdmin();
        View::render('admin/users', [
            'admin'  => $admin,
            'active' => 'users',
            'title'  => 'Users',
            'users'  => User::all(),
        ]);
    }

    public function updateRole(Request $request): never
    {
        $admin = Auth::requireAdmin();
        Csrf::verifyOrAbort($request);

        $id = (int)$request->param('id');
        $role = (string)$request->input('role', '');

        // Admins cannot demote themselves.
        if ($id !== (int)$admin['id'] && in_array($role, ['user', 'admin'], true) && User::find($id) !== null) {
            User::update($id, ['role' => $role]);
        }
        Response::redirect('/admin/users');
    }

    public function destroy(Request $request): never
    {
        $admin = Auth::requireAdmin();
        Csrf::verifyOrAbort($request);

        $id = (int)$request->param('id');
        if ($id !== (int)$admin['id']) { // cannot delete self
            User::delete($id);
        }
        Response::redirect('/admin/users');
    }
}
