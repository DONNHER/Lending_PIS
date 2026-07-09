<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Shareholder;
use App\Models\Loan;
use App\Models\Transaction;
use App\Models\User;
use App\Models\ActivityLog;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    public function index()
    {
        $user = Auth::user();

        if ($user->isAdmin()) {
            $stats = [
                'total_users' => User::count(),
                'active_now' => DB::table('personal_access_tokens')
                    ->where('last_used_at', '>', now()->subMinutes(15))
                    ->distinct('tokenable_id')
                    ->count(),
                'total_shareholders' => Shareholder::count(),
                'active_loans' => Loan::where('status', 'active')->count(),
                'total_disbursed' => Loan::where('status', 'active')->sum('amount'),
                'recent_transactions' => Transaction::with('shareholder')->latest()->take(5)->get(),
                'recent_activities' => ActivityLog::with('user:id,firstname,lastname')->latest()->take(5)->get(),
                'system_health' => $this->getSystemHealth(),
                'performance' => $this->getPerformanceMetrics(),
            ];

            return view('dashboard', compact('user', 'stats'));
        }

        // Shareholder Dashboard
        $shareholder = $user->shareholder;

        if (!$shareholder) {
            // Fallback for users without shareholder record (e.g. staff/cashier)
            $stats = [
                'total_users' => User::count(),
                'active_now' => DB::table('personal_access_tokens')
                    ->where('last_used_at', '>', now()->subMinutes(15))
                    ->distinct('tokenable_id')
                    ->count(),
                'total_shareholders' => Shareholder::count(),
                'active_loans' => Loan::where('status', 'active')->count(),
                'total_disbursed' => Loan::where('status', 'active')->sum('amount'),
                'recent_transactions' => Transaction::latest()->take(5)->get(),
                'recent_activities' => ActivityLog::latest()->take(5)->get(),
                'system_health' => $this->getSystemHealth(),
                'performance' => $this->getPerformanceMetrics(),
            ];
            return view('dashboard', compact('user', 'stats'));
        }

        $activeLoans = $shareholder->loans()->where('status', 'active')->with('transactions')->get();
        $activeLoanBalance = $activeLoans->sum('amount');
        $recentTransactions = $shareholder->transactions()->latest('date')->take(5)->get();

        return view('shareholder.dashboard', compact('user', 'shareholder', 'activeLoans', 'activeLoanBalance', 'recentTransactions'));
    }

    private function getSystemHealth()
    {
        try {
            $dbSize = DB::select("SELECT pg_size_pretty(pg_database_size(current_database())) as size")[0]->size;
        } catch (\Exception $e) {
            $dbSize = 'N/A';
        }

        $storageUsage = $this->getStorageUsage();
        if ($storageUsage >= 85) {
            NotificationService::send(
                auth()->id(),
                'URGENT: Storage Capacity Warning',
                "System storage is at {$storageUsage}%. Cleanup of old backups is highly recommended.",
                'warning',
                'high'
            );
        }

        $uptime = "N/A";
        if (PHP_OS_FAMILY === 'Linux' && file_exists('/proc/uptime')) {
            $str = file_get_contents('/proc/uptime');
            $num = (float)$str;
            $days = floor($num / 86400);
            $hours = floor(($num / 3600) % 24);
            $uptime = "{$days}d {$hours}h";
        } elseif (PHP_OS_FAMILY === 'Windows') {
            $uptime = "Windows Server";
        }

        return [
            'db_size' => $dbSize,
            'storage_usage' => $this->getStorageUsage(),
            'uptime' => $uptime
        ];
    }

    private function getStorageUsage()
    {
        try {
            $totalSpace = disk_total_space(base_path());
            $freeSpace = disk_free_space(base_path());
            $usedSpace = $totalSpace - $freeSpace;
            return round(($usedSpace / $totalSpace) * 100, 1);
        } catch (\Exception $e) {
            return 0;
        }
    }

    private function getPerformanceMetrics()
    {
        $totalLogs = ActivityLog::count();
        $errorLogs = ActivityLog::where('log_type', 'error')->count();

        return [
            'error_rate' => $totalLogs > 0 ? round(($errorLogs / $totalLogs) * 100, 2) : 0,
            'avg_response_time' => '240ms', // Mocked or fetched from profiling logs if available
        ];
    }
}
