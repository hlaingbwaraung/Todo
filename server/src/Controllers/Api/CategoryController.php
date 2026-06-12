<?php

declare(strict_types=1);

namespace App\Controllers\Api;

use App\Core\Request;
use App\Core\Response;
use App\Models\Category;

final class CategoryController
{
    public function index(Request $request): never
    {
        $rows = Category::allWithCounts(true);
        Response::data(array_map([Category::class, 'shape'], $rows));
    }
}
