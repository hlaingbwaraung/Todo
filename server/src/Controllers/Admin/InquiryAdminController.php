<?php

declare(strict_types=1);

namespace App\Controllers\Admin;

use App\Core\Auth;
use App\Core\Csrf;
use App\Core\Request;
use App\Core\Response;
use App\Core\View;
use App\Models\Inquiry;

final class InquiryAdminController
{
    public function index(Request $request): never
    {
        $admin = Auth::requireAdmin();
        View::render('admin/inquiries', [
            'admin'     => $admin,
            'active'    => 'inquiries',
            'title'     => 'Inquiries',
            'inquiries' => Inquiry::allWithProperty(),
        ]);
    }

    public function updateStatus(Request $request): never
    {
        Auth::requireAdmin();
        Csrf::verifyOrAbort($request);

        $id = (int)$request->param('id');
        $status = (string)$request->input('status', '');
        if (Inquiry::find($id) !== null && in_array($status, ['new', 'in_progress', 'closed'], true)) {
            Inquiry::updateStatus($id, $status);
        }
        Response::redirect('/admin/inquiries');
    }

    public function destroy(Request $request): never
    {
        Auth::requireAdmin();
        Csrf::verifyOrAbort($request);

        Inquiry::delete((int)$request->param('id'));
        Response::redirect('/admin/inquiries');
    }
}
