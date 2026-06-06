<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\ActivityLog;
use App\Models\LoanRequest;
use App\Models\Loan;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

/**
 * Class DashboardController
 * 
 * Aggregates system-wide data for the Administrator and Staff dashboards.
 * Provides charts, health metrics, and quick-access statistics.
 * Optimized for PostgreSQL (Supabase).
 * 
 * @package App\Http\Controllers\Api
 */
class DashboardController extends Controller
{
    /**
     * Fetch comprehensive dashboard statistics.
     * 
     * @param Request $request Supports 'range' (day, week, month, year)
     * @return \Illuminate\Http\JsonResponse
     */
    public function getStats(Request $request)
    {
        $range = $request->get('range', 'week');
        $startDate = $this->getStartDate($range);

        return response()->json([
            'success' => true,
            'user_stats' => $this->getUserStats($startDate),
            'transaction_stats' => $this->getTransactionStats($startDate, $range),
            'system_health' => $this->getSystemHealth(),
            'recent_activities' => $this->getRecentActivities(),
            'performance_metrics' => $this->getPerformanceMetrics($startDate),
            'quick_actions' => $this->getQuickActions(),
        ]);
    }

    /**
     * Helper to determine start date based on the selected range.
     */
    private function getStartDate($range)
    {
        return match ($range) {
            'day' => now()->startOfDay(),
            'week' => now()->subDays(7)->startOfDay(),
            'month' => now()->subMonth()->startOfDay(),
            'year' => now()->subYear()->startOfDay(),
            default => now()->subDays(7)->startOfDay(),
        };
    }

    /**
     * Calculate user registration trends and current active count.
     */
    private function getUserStats($startDate)
    {
        $totalUsers = User::count();
        
        // Active now: users who had activity in the last 15 minutes
        $activeNow = DB::table('personal_access_tokens')
            ->where('last_used_at', '>', now()->subMinutes(15))
            ->distinct('tokenable_id')
            ->count();

        // PostgreSQL compliant grouping
        $newRegistrations = User::where('created_at', '>=', $startDate)
            ->select(DB::raw('CAST(created_at AS DATE) as date'), DB::raw('count(*) as count'))
            ->groupBy('date')
            ->orderBy('date')
            ->get();

        return [
            'total_users' => $totalUsers,
            'active_now' => $activeNow,
            'new_registrations_chart' => [
                'labels' => $newRegistrations->pluck('date'),
                'datasets' => [
                    [
                        'label' => 'New Registrations',
                        'data' => $newRegistrations->pluck('count'),
                    ]
                ]
            ],
        ];
    }

    /**
     * Fetch system activity stats and format for chart display.
     * Optimized with cross-database support for DATE_FORMAT/TO_CHAR.
     */
    private function getTransactionStats($startDate, $range)
    {
        $isPgSql = DB::getDriverName() === 'pgsql';

        $query = ActivityLog::where('log_type', ActivityLog::TYPE_TRANSACTION)
            ->where('created_at', '>=', $startDate);

        if ($isPgSql) {
            $format = match ($range) {
                'day' => 'HH24:00',
                'week', 'month' => 'YYYY-MM-DD',
                'year' => 'YYYY-MM',
            };
            $labelExpr = "TO_CHAR(created_at, '$format')";
        } else {
            $format = match ($range) {
                'day' => '%H:00',
                'week', 'month' => '%Y-%m-%d',
                'year' => '%Y-%m',
            };
            $labelExpr = "DATE_FORMAT(created_at, '$format')";
        }

        $chartData = $query->select(
                DB::raw("$labelExpr as label"), 
                DB::raw('count(*) as count')
            )
            ->groupBy('label')
            ->orderBy('label')
            ->get();

        return [
            'activity_chart' => [
                'labels' => $chartData->pluck('label'),
                'datasets' => [
                    [
                        'label' => 'System Transactions',
                        'data' => $chartData->pluck('count'),
                    ]
                ]
            ],
            'total_count' => $query->count(),
        ];
    }

    /**
     * Gather technical environment data (Disk space, versions).
     */
    private function getSystemHealth()
    {
        $isPgSql = DB::getDriverName() === 'pgsql';
        $dbSize = 0;

        try {
            if ($isPgSql) {
                $dbName = config('database.connections.pgsql.database');
                $size = DB::select("SELECT pg_database_size(?) / 1024 / 1024 AS size", [$dbName]);
                $dbSize = round($size[0]->size, 2);
            } else {
                $dbName = config('database.connections.mysql.database');
                $size = DB::select("SELECT SUM(data_length + index_length) / 1024 / 1024 AS size FROM information_schema.TABLES WHERE table_schema = ?", [$dbName]);
                $dbSize = round($size[0]->size, 2);
            }
        } catch (\Exception $e) {}

        $storagePath = storage_path();
        $freeSpace = @disk_free_space($storagePath) ?: 0;
        $totalSpace = @disk_total_space($storagePath) ?: 1;
        $usedSpace = $totalSpace - $freeSpace;

        return [
            'database_size_mb' => $dbSize,
            'storage_used_percent' => round(($usedSpace / $totalSpace) * 100, 2),
            'free_space_gb' => round($freeSpace / 1024 / 1024 / 1024, 2),
            'php_version' => PHP_VERSION,
            'laravel_version' => app()->version(),
            'server_environment' => config('app.env'),
            'database_engine' => $isPgSql ? 'PostgreSQL (Supabase)' : 'MySQL',
        ];
    }

    /**
     * Fetch the 10 most recent activity logs for the dashboard feed.
     */
    private function getRecentActivities()
    {
        return ActivityLog::with('user:id,firstname,lastname,avatar_url')
            ->latest('created_at')
            ->limit(10)
            ->get();
    }

    /**
     * Calculate API response times and error rates.
     */
    private function getPerformanceMetrics($startDate)
    {
        $accessLogs = ActivityLog::where('log_type', ActivityLog::TYPE_ACCESS)
            ->where('created_at', '>=', $startDate)
            ->get();

        $totalRequests = $accessLogs->count();
        $errorCount = ActivityLog::where('log_type', ActivityLog::TYPE_ERROR)
            ->where('created_at', '>=', $startDate)
            ->count();

        $avgResponseTime = 0;
        if ($totalRequests > 0) {
            $durations = $accessLogs->map(function($log) {
                // Ensure accessing duration safely
                return is_array($log->old_values) ? ($log->old_values['duration_ms'] ?? 0) : 0;
            });
            $avgResponseTime = round($durations->avg(), 2);
        }

        return [
            'avg_response_time_ms' => $avgResponseTime,
            'error_rate_percent' => $totalRequests > 0 ? round(($errorCount / $totalRequests) * 100, 2) : 0,
            'total_errors' => $errorCount,
            'total_requests' => $totalRequests,
        ];
    }

    /**
     * Fetch badge counts for high-priority items.
     */
    private function getQuickActions()
    {
        return [
            'pending_loan_requests' => LoanRequest::where('status', 'pending')->count(),
            'active_loans' => Loan::where('status', 'active')->count(),
            'low_inventory_products' => DB::table('products')
                ->join('grocery_batches', 'products.id', '=', 'grocery_batches.product_id')
                ->where('grocery_batches.remaining_quantity', '<', 10)
                ->distinct('products.id')
                ->count(),
        ];
    }
}
