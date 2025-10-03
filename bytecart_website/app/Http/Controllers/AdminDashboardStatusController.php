<?php

/**
 * AdminDashboardStatusController
 *
 * Purpose:
 * - Builds admin dashboard status data and renders the dashboard view.
 * - Passes both the status object and flattened variables to the Blade view.
 */

namespace App\Http\Controllers;

use App\Models\AdminDashboardStatus;
use Illuminate\Http\Request;

class AdminDashboardStatusController extends Controller
{
    /**
     * Render the admin dashboard with computed status metrics.
     */
    public function index(Request $request)
    {
        // Build dashboard status data
        $status = AdminDashboardStatus::build();

        // Render dashboard view with the status object and flattened variables
        return view('dashboard', array_merge(['status' => $status], $status->toViewData()));
    }
}
