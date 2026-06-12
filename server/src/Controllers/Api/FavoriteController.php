<?php

declare(strict_types=1);

namespace App\Controllers\Api;

use App\Core\Auth;
use App\Core\Request;
use App\Core\Response;
use App\Core\Validator;
use App\Models\Favorite;
use App\Models\Property;

final class FavoriteController
{
    public function index(Request $request): never
    {
        $user = Auth::require($request);
        $rows = Favorite::propertiesFor((int)$user['id']);
        Response::data(Property::shapeList($rows, (int)$user['id']));
    }

    public function store(Request $request): never
    {
        $user = Auth::require($request);

        Validator::validateOrAbort($request->body, [
            'property_id' => 'required|integer',
        ]);

        $propertyId = (int)$request->input('property_id');
        $property = Property::findPublished($propertyId);
        if ($property === null) {
            Response::notFound('Property not found.');
        }

        if (!Favorite::exists((int)$user['id'], $propertyId)) {
            Favorite::add((int)$user['id'], $propertyId);
        }

        Response::data(['property_id' => $propertyId, 'is_favorite' => true], 201);
    }

    public function destroy(Request $request): never
    {
        $user = Auth::require($request);
        $propertyId = (int)$request->param('property_id');

        $removed = Favorite::remove((int)$user['id'], $propertyId);
        if ($removed === 0) {
            Response::notFound('Favorite not found.');
        }

        Response::data(['property_id' => $propertyId, 'is_favorite' => false]);
    }
}
