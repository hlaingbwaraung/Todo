<?php

declare(strict_types=1);

namespace App\Controllers\Admin;

use App\Core\Auth;
use App\Core\Database as DB;
use App\Core\Request;
use App\Core\View;
use App\Models\Inquiry;
use App\Models\Reservation;
use App\Models\User;

final class DashboardController
{
    public function index(Request $request): never
    {
        $admin = Auth::requireAdmin();

        $stats = [
            'properties_total'     => (int)(DB::selectOne('SELECT COUNT(*) AS c FROM properties')['c'] ?? 0),
            'properties_published' => (int)(DB::selectOne("SELECT COUNT(*) AS c FROM properties WHERE status = 'published'")['c'] ?? 0),
            'users'                => User::count(),
            'new_inquiries'        => Inquiry::countByStatus('new'),
            'pending_reservations' => Reservation::countByStatus('pending'),
            'total_views'          => (int)(DB::selectOne('SELECT COALESCE(SUM(view_count),0) AS c FROM properties')['c'] ?? 0),
        ];

        View::render('admin/dashboard', [
            'admin'               => $admin,
            'active'              => 'dashboard',
            'title'               => 'Dashboard',
            'stats'               => $stats,
            'recentInquiries'     => Inquiry::recent(6),
            'recentReservations'  => Reservation::recent(6),
            'inquiriesPerDay'     => Inquiry::perDay(7),
        ]);
    }
}
