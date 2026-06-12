<?php

declare(strict_types=1);

namespace App\Controllers\Api;

use App\Core\Auth;
use App\Core\Request;
use App\Core\Response;
use App\Core\Validator;
use App\Models\Device;

final class DeviceController
{
    public function store(Request $request): never
    {
        $user = Auth::require($request);

        Validator::validateOrAbort($request->body, [
            'device_token' => 'required|string|max:255',
            'platform'     => 'required|in:ios,android',
        ]);

        $device = Device::upsert(
            (int)$user['id'],
            (string)$request->input('device_token'),
            (string)$request->input('platform')
        );

        Response::data(Device::shape($device), 201);
    }
}
