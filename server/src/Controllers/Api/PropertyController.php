<?php

declare(strict_types=1);

namespace App\Controllers\Api;

use App\Core\Auth;
use App\Core\Request;
use App\Core\Response;
use App\Models\Favorite;
use App\Models\Property;

final class PropertyController
{
    public function index(Request $request): never
    {
        Auth::optional($request);

        $result = Property::search($request->query, true);
        $data = Property::shapeList($result['rows'], $request->userId());

        Response::data($data, 200, $result['meta']);
    }

    public function show(Request $request): never
    {
        Auth::optional($request);

        $id = (int)$request->param('id');
        $row = Property::findPublished($id);
        if ($row === null) {
            Response::notFound('Property not found.');
        }

        Property::incrementViewCount($id);
        $row['view_count'] = (int)$row['view_count'] + 1;

        $isFavorite = null;
        if ($request->userId() !== null) {
            $isFavorite = Favorite::exists($request->userId(), $id);
        }

        Response::data(Property::shape($row, true, null, null, $isFavorite));
    }

    public function similar(Request $request): never
    {
        Auth::optional($request);

        $id = (int)$request->param('id');
        $row = Property::findPublished($id);
        if ($row === null) {
            Response::notFound('Property not found.');
        }

        $rows = Property::similar($row);
        Response::data(Property::shapeList($rows, $request->userId()));
    }
}
