<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use App\Models\SiteSetting;
use Illuminate\Support\Facades\Auth;

class CheckMaintenanceMode
{
    public function handle(Request $request, Closure $next)
    {
        $maintenanceMode = SiteSetting::get('maintenance_mode', '0');

        if ($maintenanceMode === '1') {
            // Allow Admins to bypass
            if (Auth::check() && Auth::user()->isAdmin()) {
                return $next($request);
            }

            // Exclude login/logout and admin routes from redirect loop if needed,
            // but generally we want a full block except for active admin sessions.
            if ($request->is('login') || $request->is('logout') || $request->is('admin/*')) {
                return $next($request);
            }

            $message = SiteSetting::get('maintenance_message', 'The system is currently undergoing maintenance. Please try again later.');

            return response()->view('errors.maintenance', compact('message'), 503);
        }

        return $next($request);
    }
}
