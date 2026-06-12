<?php

declare(strict_types=1);

namespace App\Controllers\Admin;

use App\Core\Auth;
use App\Core\Csrf;
use App\Core\Request;
use App\Core\Response;
use App\Core\View;
use App\Models\Reservation;

final class ReservationAdminController
{
    public function index(Request $request): never
    {
        $admin = Auth::requireAdmin();
        View::render('admin/reservations', [
            'admin'        => $admin,
            'active'       => 'reservations',
            'title'        => 'Reservations',
            'reservations' => Reservation::allWithProperty(),
        ]);
    }

    public function updateStatus(Request $request): never
    {
        Auth::requireAdmin();
        Csrf::verifyOrAbort($request);

        $id = (int)$request->param('id');
        $status = (string)$request->input('status', '');
        if (Reservation::find($id) !== null && in_array($status, Reservation::STATUSES, true)) {
            Reservation::updateStatus($id, $status);
        }
        Response::redirect('/admin/reservations');
    }

    public function destroy(Request $request): never
    {
        Auth::requireAdmin();
        Csrf::verifyOrAbort($request);

        Reservation::delete((int)$request->param('id'));
        Response::redirect('/admin/reservations');
    }
}
