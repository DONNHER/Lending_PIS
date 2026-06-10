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

        // 🚀 OPTIMIZATION: Do not log GET requests (viewing/fetching) to prevent database bloat.
        // Only log mutations (POST, PUT, PATCH, DELETE) or non-GET access if necessary.
        if (Auth::check() 
            && !$request->isMethod('GET') 
            && !str_contains($request->path(), 'activity-logs') 
            && !str_contains($request->path(), 'dashboard')) {
            
            ActivityLog::create([
                'user_id' => Auth::id(),
                'action' => 'Access',
                'log_type' => ActivityLog::TYPE_ACCESS,
                'description' => "Action: " . $request->path() . " (" . $request->method() . ")",
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
