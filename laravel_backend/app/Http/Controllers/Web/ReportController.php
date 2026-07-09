<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\ActivityLog;
use App\Models\Transaction;
use App\Models\User;
use App\Models\ReportFavorite;
use App\Models\Loan;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class ReportController extends Controller
{
    public function index()
    {
        $favorites = ReportFavorite::where('user_id', auth()->id())->get();
        return view('admin.reports.index', compact('favorites'));
    }

    public function generate(Request $request)
    {
        $type = $request->get('type');
        $format = $request->get('format', 'print');

        return match ($type) {
            'user_activity' => $this->userActivityReport($request, $format),
            'transaction_summary' => $this->transactionSummaryReport($request, $format),
            'audit_trail' => $this->auditTrailReport($request, $format),
            'system_usage' => $this->systemUsageReport($request, $format),
            default => back()->with('error', 'Invalid report type selected.'),
        };
    }

    private function userActivityReport(Request $request, $format)
    {
        $query = ActivityLog::with('user');

        if ($request->filled('start_date')) {
            $query->where('created_at', '>=', $request->start_date);
        }
        if ($request->filled('end_date')) {
            $query->where('created_at', '<=', Carbon::parse($request->end_date)->endOfDay());
        }
        if ($request->filled('role')) {
            $query->whereHas('user', function($q) use ($request) {
                $q->where('role', $request->role);
            });
        }
        if ($request->filled('action_type')) {
            $query->where('log_type', $request->action_type);
        }

        $data = $query->latest()->get();

        if ($format === 'csv') {
            return $this->exportCsv($data, 'user_activity_report');
        }

        return view('admin.reports.templates.user_activity', compact('data', 'request'));
    }

    private function transactionSummaryReport(Request $request, $format)
    {
        $query = Transaction::with('shareholder');

        if ($request->filled('period')) {
            $startDate = match($request->period) {
                'today' => now()->startOfDay(),
                'week' => now()->startOfWeek(),
                'month' => now()->startOfMonth(),
                'year' => now()->startOfYear(),
                default => null
            };
            if ($startDate) $query->where('date', '>=', $startDate);
        }

        if ($request->filled('category')) {
            $query->where('type', $request->category);
        }

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        $data = $query->latest('date')->get();

        if ($format === 'csv') {
            return $this->exportCsv($data, 'transaction_summary_report');
        }

        return view('admin.reports.templates.transaction_summary', compact('data', 'request'));
    }

    private function auditTrailReport(Request $request, $format)
    {
        $query = ActivityLog::with('user');

        if ($request->filled('user_id')) {
            $query->where('user_id', $request->user_id);
        }
        if ($request->filled('date')) {
            $query->whereDate('created_at', $request->date);
        }
        if ($request->filled('module')) {
            $query->where('log_type', $request->module);
        }

        $data = $query->latest()->get();

        if ($format === 'csv') {
            return $this->exportCsv($data, 'audit_trail_report');
        }

        return view('admin.reports.templates.audit_trail', compact('data', 'request'));
    }

    private function systemUsageReport(Request $request, $format)
    {
        $period = $request->get('period', 'monthly');

        $stats = match($period) {
            'monthly' => $this->getMonthlyStats(),
            'quarterly' => $this->getQuarterlyStats(),
            'yearly' => $this->getYearlyStats(),
            default => $this->getMonthlyStats()
        };

        return view('admin.reports.templates.system_usage', compact('stats', 'period', 'request'));
    }

    private function getMonthlyStats()
    {
        return ActivityLog::select(
            DB::raw("TO_CHAR(created_at, 'YYYY-MM') as label"),
            DB::raw('count(*) as count')
        )
        ->groupBy('label')
        ->orderBy('label', 'asc')
        ->take(12)
        ->get();
    }

    private function getQuarterlyStats()
    {
        // PostgreSQL specific
        return ActivityLog::select(
            DB::raw("concat(extract(year from created_at), '-Q', extract(quarter from created_at)) as label"),
            DB::raw('count(*) as count')
        )
        ->groupBy('label')
        ->orderBy('label', 'asc')
        ->take(8)
        ->get();
    }

    private function getYearlyStats()
    {
        return ActivityLog::select(
            DB::raw("extract(year from created_at) as label"),
            DB::raw('count(*) as count')
        )
        ->groupBy('label')
        ->orderBy('label', 'asc')
        ->get();
    }

    public function saveFavorite(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'report_type' => 'required|string',
            'filters' => 'required|array'
        ]);

        ReportFavorite::create([
            'user_id' => auth()->id(),
            'name' => $request->name,
            'report_type' => $request->report_type,
            'filters' => $request->filters
        ]);

        return back()->with('success', 'Report configuration saved to favorites.');
    }

    public function deleteFavorite(ReportFavorite $report)
    {
        if ($report->user_id !== auth()->id()) abort(403);
        $report->delete();
        return back()->with('success', 'Favorite report configuration removed.');
    }

    private function exportCsv($data, $filename)
    {
        $headers = [
            "Content-type"        => "text/csv",
            "Content-Disposition" => "attachment; filename={$filename}_" . date('Y-m-d') . ".csv",
            "Pragma"              => "no-cache",
            "Cache-Control"       => "must-revalidate, post-check=0, pre-check=0",
            "Expires"             => "0"
        ];

        $callback = function() use($data) {
            $file = fopen('php://output', 'w');
            if ($data->isEmpty()) {
                fputcsv($file, ['No data found']);
            } else {
                fputcsv($file, array_keys($data->first()->toArray()));
                foreach ($data as $row) {
                    fputcsv($file, $row->toArray());
                }
            }
            fclose($file);
        };

        return response()->stream($callback, 200, $headers);
    }
}
