<?php

namespace App\Exceptions;

use Illuminate\Foundation\Exceptions\Handler as ExceptionHandler;
use Throwable;
use App\Models\ActivityLog;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class Handler extends ExceptionHandler
{
    protected $levels = [];

    protected $dontReport = [];

    protected $dontFlash = [
        'current_password',
        'password',
        'password_confirmation',
    ];

    public function register(): void
    {
        $this->reportable(function (Throwable $e) {
            try {
                // Check if we are in a state where DB is available
                if (class_exists('Illuminate\Support\Facades\DB')) {
                    ActivityLog::create([
                        'user_id' => Auth::id(),
                        'action' => 'System Error',
                        'log_type' => ActivityLog::TYPE_ERROR,
                        'description' => $e->getMessage(),
                        'old_values' => [
                            'file' => $e->getFile(),
                            'line' => $e->getLine(),
                            'trace' => substr($e->getTraceAsString(), 0, 1000)
                        ],
                        'ip_address' => Request::ip(),
                        'device_info' => Request::userAgent(),
                    ]);
                }
            } catch (Throwable $dbEx) {
                // Fallback to standard logging if DB is down or logic fails
                Log::error('Secondary error while logging to ActivityLog: ' . $dbEx->getMessage());
            }
        });
    }
}
