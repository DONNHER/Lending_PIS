<?php

namespace App\Http\Middleware;

use Closure;
use App\Models\ActivityLog;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class LogAccess
{
    public function handle(Request $request, Closure $next)
    {
        $start = microtime(true);

        $response = $next($request);

        $duration = round((microtime(true) - $start) * 1000, 2); // duration in ms

        // Only log successful GET requests or mutations, avoiding logging the log viewer itself too much
        if (Auth::check() && !str_contains($request->path(), 'activity-logs') && !str_contains($request->path(), 'dashboard')) {
            ActivityLog::create([
                'user_id' => Auth::id(),
                'action' => 'Access',
                'log_type' => ActivityLog::TYPE_ACCESS,
                'description' => "Visited: " . $request->path() . " (" . $request->method() . ")",
                'ip_address' => $request->ip(),
                'device_info' => $request->userAgent(),
                'old_values' => [
                    'duration_ms' => $duration,
                    'method' => $request->method(),
                    'path' => $request->path(),
                    'status' => $response->getStatusCode()
                ]
            ]);
        }

        return $response;
    }
}
