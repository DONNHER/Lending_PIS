<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ActivityLog;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

/**
 * Class ActivityLogController
 * 
 * Provides administrative access to the system's audit trail.
 * Allows searching, filtering, and exporting of activity logs.
 * 
 * @package App\Http\Controllers\Api
 */
class ActivityLogController extends Controller
{
    /**
     * Display a listing of activity logs with advanced filtering.
     * Supports search by action/description/IP and filtering by type/user/date.
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function index(Request $request)
    {
        $query = ActivityLog::with('user');

        // Global Search
        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function($q) use ($search) {
                $q->where('action', 'like', "%{$search}%")
                  ->orWhere('description', 'like', "%{$search}%")
                  ->orWhere('ip_address', 'like', "%{$search}%");
            });
        }

        // Filter by Log Type (e.g., auth, transaction, error)
        if ($request->filled('log_type')) {
            $query->where('log_type', $request->log_type);
        }

        // Filter by User
        if ($request->filled('user_id')) {
            $query->where('user_id', $request->user_id);
        }

        // Filter for suspicious activity
        if ($request->filled('is_suspicious')) {
            $query->where('is_suspicious', $request->boolean('is_suspicious'));
        }

        // Date Range Filtering
        if ($request->filled('start_date')) {
            $query->where('created_at', '>=', Carbon::parse($request->start_date)->startOfDay());
        }

        if ($request->filled('end_date')) {
            $query->where('created_at', '<=', Carbon::parse($request->end_date)->endOfDay());
        }

        $perPage = $request->get('limit', 20);
        $logs = $query->latest('created_at')->paginate($perPage);

        return response()->json([
            'success' => true,
            'data' => $logs->items(),
            'meta' => [
                'current_page' => $logs->currentPage(),
                'last_page' => $logs->lastPage(),
                'total' => $logs->total(),
            ]
        ]);
    }

    /**
     * Export the filtered activity logs to a CSV file.
     * 
     * @param Request $request
     * @return \Symfony\Component\HttpFoundation\StreamedResponse
     */
    public function export(Request $request)
    {
        $query = ActivityLog::latest('created_at');
        
        // Apply same filters as index method
        if ($request->filled('log_type')) $query->where('log_type', $request->log_type);
        if ($request->filled('start_date')) $query->where('created_at', '>=', $request->start_date);
        if ($request->filled('end_date')) $query->where('created_at', '<=', $request->end_date);

        $logs = $query->get();
        
        $filename = "activity_logs_" . date('Y-m-d_H-i-s') . ".csv";
        $headers = [
            "Content-type"        => "text/csv",
            "Content-Disposition" => "attachment; filename=$filename",
            "Pragma"              => "no-cache",
            "Cache-Control"       => "must-revalidate, post-check=0, pre-check=0",
            "Expires"             => "0"
        ];

        $columns = ['ID', 'User ID', 'Log Type', 'Action', 'Description', 'IP Address', 'Device', 'Suspicious', 'Timestamp'];

        $callback = function() use($logs, $columns) {
            $file = fopen('php://output', 'w');
            fputcsv($file, $columns);

            foreach ($logs as $log) {
                fputcsv($file, [
                    $log->id,
                    $log->user_id,
                    $log->log_type,
                    $log->action,
                    $log->description,
                    $log->ip_address,
                    $log->device_info,
                    $log->is_suspicious ? 'YES' : 'NO',
                    $log->created_at,
                ]);
            }
            fclose($file);
        };

        return response()->stream($callback, 200, $headers);
    }

    /**
     * Maintenance: Delete logs older than 90 days.
     * Generally triggered by an admin or scheduled task.
     */
    public function cleanup()
    {
        $count = ActivityLog::where('created_at', '<', now()->subDays(90))->delete();
        
        return response()->json([
            'success' => true,
            'message' => "Archived/Deleted $count logs older than 90 days."
        ]);
    }

    /**
     * Get total count of logs, optionally filtered by user.
     */
    public function count(Request $request)
    {
        $query = ActivityLog::query();
        if ($request->has('user_id')) {
            $query->where('user_id', $request->user_id);
        }
        return response()->json([
            'success' => true,
            'total' => $query->count()
        ]);
    }
}
