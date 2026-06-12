<?php

declare(strict_types=1);

namespace App\Controllers\Admin;

use App\Core\Auth;
use App\Core\Csrf;
use App\Core\Request;
use App\Core\Response;
use App\Core\View;
use App\Models\User;

final class AuthAdminController
{
    public function showLogin(Request $request): never
    {
        if (Auth::adminUser() !== null) {
            Response::redirect('/admin');
        }
        View::renderBare('admin/login', ['error' => null, 'email' => '']);
    }

    public function login(Request $request): never
    {
        Csrf::verifyOrAbort($request);

        $email = strtolower(trim((string)$request->input('email', '')));
        $password = (string)$request->input('password', '');

        $user = $email !== '' ? User::findByEmail($email) : null;
        if (
            $user === null
            || $user['role'] !== 'admin'
            || !password_verify($password, (string)$user['password_hash'])
        ) {
            View::renderBare('admin/login', [
                'error' => 'Invalid credentials or insufficient privileges.',
                'email' => $email,
            ]);
        }

        Auth::loginAdmin((int)$user['id']);
        Response::redirect('/admin');
    }

    public function logout(Request $request): never
    {
        Csrf::verifyOrAbort($request);
        Auth::logoutAdmin();
        Response::redirect('/admin/login');
    }
}
