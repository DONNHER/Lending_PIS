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

class DashboardController extends Controller
{
    public function getStats(Request $request)
    {
        $range = $request->get('range', 'week');
        $startDate = $this->getStartDate($range);

        return response()->json([
            'success' => true,
            'user_stats' => $this->getUserStats($startDate, $range),
            'transaction_stats' => $this->getTransactionStats($startDate, $range),
            'recent_activities' => ActivityLog::with('user:id,firstname,lastname')->latest()->limit(5)->get(),
        ]);
    }

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

    private function getUserStats($startDate, $range)
    {
        $isPgSql = DB::getDriverName() === 'pgsql';
        $format = $isPgSql 
            ? match ($range) { 'day' => 'HH24:00', 'year' => 'YYYY-MM', default => 'YYYY-MM-DD' }
            : match ($range) { 'day' => '%H:00', 'year' => '%Y-%m', default => '%Y-%m-%d' };
            
        $labelExpr = $isPgSql ? "TO_CHAR(created_at, '$format')" : "DATE_FORMAT(created_at, '$format')";

        $registrationTrend = User::where('created_at', '>=', $startDate)
            ->select(DB::raw("$labelExpr as label"), DB::raw('count(*) as count'))
            ->groupBy(DB::raw($labelExpr))
            ->orderBy(DB::raw($labelExpr), 'asc')
            ->get();

        return [
            'total_users' => User::count(),
            'active_now' => DB::table('personal_access_tokens')
                ->where('last_used_at', '>', now()->subMinutes(15))
                ->distinct('tokenable_id')
                ->count(),
            'new_registrations' => User::where('created_at', '>=', $startDate)->count(),
            'trend' => [
                'labels' => $registrationTrend->pluck('label'),
                'data' => $registrationTrend->pluck('count'),
            ]
        ];
    }

    private function getTransactionStats($startDate, $range)
    {
        $isPgSql = DB::getDriverName() === 'pgsql';
        
        $format = $isPgSql 
            ? match ($range) { 'day' => 'HH24:00', 'year' => 'YYYY-MM', default => 'YYYY-MM-DD' }
            : match ($range) { 'day' => '%H:00', 'year' => '%Y-%m', default => '%Y-%m-%d' };
            
        $labelExpr = $isPgSql ? "TO_CHAR(created_at, '$format')" : "DATE_FORMAT(created_at, '$format')";

        $chartData = ActivityLog::where('log_type', 'transaction')
            ->where('created_at', '>=', $startDate)
            ->select(DB::raw("$labelExpr as label"), DB::raw('count(*) as count'))
            ->groupBy(DB::raw($labelExpr))
            ->orderBy(DB::raw($labelExpr), 'asc')
            ->get();

        return [
            'activity_chart' => [
                'labels' => $chartData->pluck('label'),
                'datasets' => [['label' => 'Transactions', 'data' => $chartData->pluck('count')]]
            ],
            'total_count' => $chartData->sum('count'),
        ];
    }
}
