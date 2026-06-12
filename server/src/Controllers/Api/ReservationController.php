<?php

declare(strict_types=1);

namespace App\Controllers\Api;

use App\Core\Auth;
use App\Core\Request;
use App\Core\Response;
use App\Core\Validator;
use App\Models\Property;
use App\Models\Reservation;

final class ReservationController
{
    public function store(Request $request): never
    {
        Auth::optional($request);

        Validator::validateOrAbort($request->body, [
            'property_id'    => 'required|integer',
            'name'           => 'required|string|max:190',
            'email'          => 'required|email|max:190',
            'phone'          => 'string|max:50',
            'preferred_date' => 'required|date',
            'preferred_time' => 'required|time',
            'message'        => 'string|max:5000',
        ]);

        $date = (string)$request->input('preferred_date');
        if ($date < date('Y-m-d')) {
            Response::validationError(['preferred_date' => 'Preferred date must be today or later.']);
        }

        $propertyId = (int)$request->input('property_id');
        if (Property::findPublished($propertyId) === null) {
            Response::notFound('Property not found.');
        }

        $id = Reservation::create([
            'property_id'    => $propertyId,
            'user_id'        => $request->userId(),
            'name'           => trim((string)$request->input('name')),
            'email'          => trim((string)$request->input('email')),
            'phone'          => $request->input('phone') !== null && $request->input('phone') !== ''
                ? (string)$request->input('phone') : null,
            'preferred_date' => $date,
            'preferred_time' => (string)$request->input('preferred_time'),
            'message'        => $request->input('message') !== null && $request->input('message') !== ''
                ? (string)$request->input('message') : null,
        ]);

        Response::data(Reservation::shape(Reservation::find($id)), 201);
    }

    public function mine(Request $request): never
    {
        $user = Auth::require($request);
        $rows = Reservation::forUser((int)$user['id']);
        Response::data(array_map([Reservation::class, 'shape'], $rows));
    }
}
