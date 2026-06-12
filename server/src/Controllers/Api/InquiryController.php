<?php

declare(strict_types=1);

namespace App\Controllers\Api;

use App\Core\Auth;
use App\Core\Request;
use App\Core\Response;
use App\Core\Validator;
use App\Models\Inquiry;
use App\Models\Property;

final class InquiryController
{
    public function store(Request $request): never
    {
        Auth::optional($request);

        Validator::validateOrAbort($request->body, [
            'property_id' => 'required|integer',
            'name'        => 'required|string|max:190',
            'email'       => 'required|email|max:190',
            'phone'       => 'string|max:50',
            'message'     => 'required|string|max:5000',
        ]);

        $propertyId = (int)$request->input('property_id');
        if (Property::findPublished($propertyId) === null) {
            Response::notFound('Property not found.');
        }

        $id = Inquiry::create([
            'property_id' => $propertyId,
            'user_id'     => $request->userId(),
            'name'        => trim((string)$request->input('name')),
            'email'       => trim((string)$request->input('email')),
            'phone'       => $request->input('phone') !== null && $request->input('phone') !== ''
                ? (string)$request->input('phone') : null,
            'message'     => (string)$request->input('message'),
        ]);

        Response::data(Inquiry::shape(Inquiry::find($id)), 201);
    }

    public function mine(Request $request): never
    {
        $user = Auth::require($request);
        $rows = Inquiry::forUser((int)$user['id']);
        Response::data(array_map([Inquiry::class, 'shape'], $rows));
    }
}
