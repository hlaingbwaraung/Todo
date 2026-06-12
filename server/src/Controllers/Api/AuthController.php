<?php

declare(strict_types=1);

namespace App\Controllers\Api;

use App\Core\Auth;
use App\Core\Request;
use App\Core\Response;
use App\Core\Validator;
use App\Models\User;

final class AuthController
{
    public function register(Request $request): never
    {
        Validator::validateOrAbort($request->body, [
            'name'     => 'required|string|max:190',
            'email'    => 'required|email|max:190',
            'password' => 'required|string|min:8',
            'phone'    => 'string|max:50',
        ]);

        $email = strtolower(trim((string)$request->input('email')));
        if (User::findByEmail($email) !== null) {
            Response::validationError(['email' => 'Email is already registered.']);
        }

        $id = User::create(
            trim((string)$request->input('name')),
            $email,
            (string)$request->input('password'),
            $request->input('phone') !== null ? (string)$request->input('phone') : null
        );

        $user = User::find($id);
        Response::data([
            'token' => Auth::issueToken($id),
            'user'  => User::shape($user),
        ], 201);
    }

    public function login(Request $request): never
    {
        Validator::validateOrAbort($request->body, [
            'email'    => 'required|email',
            'password' => 'required|string',
        ]);

        $user = User::findByEmail(strtolower(trim((string)$request->input('email'))));
        if ($user === null || !password_verify((string)$request->input('password'), (string)$user['password_hash'])) {
            Response::unauthorized('Invalid email or password.');
        }

        Response::data([
            'token' => Auth::issueToken((int)$user['id']),
            'user'  => User::shape($user),
        ]);
    }

    public function me(Request $request): never
    {
        $user = Auth::require($request);
        Response::data(User::shape($user));
    }

    public function updateMe(Request $request): never
    {
        $user = Auth::require($request);

        Validator::validateOrAbort($request->body, [
            'name'     => 'string|max:190',
            'phone'    => 'string|max:50',
            'password' => 'string|min:8',
        ]);

        $fields = [];
        if ($request->input('name') !== null && trim((string)$request->input('name')) !== '') {
            $fields['name'] = trim((string)$request->input('name'));
        }
        if (array_key_exists('phone', $request->body)) {
            $phone = $request->input('phone');
            $fields['phone'] = ($phone === null || $phone === '') ? null : (string)$phone;
        }
        if ($request->input('password') !== null && $request->input('password') !== '') {
            $current = (string)$request->input('current_password', '');
            if (!password_verify($current, (string)$user['password_hash'])) {
                Response::validationError(['current_password' => 'Current password is incorrect.']);
            }
            $fields['password_hash'] = password_hash((string)$request->input('password'), PASSWORD_DEFAULT);
        }

        User::update((int)$user['id'], $fields);
        Response::data(User::shape(User::find((int)$user['id'])));
    }
}
