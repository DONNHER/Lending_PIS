<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Loan;
use App\Models\LoanRequest;
use App\Models\Transaction;
use App\Models\Shareholder;
use App\Models\ActivityLog;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class LoanController extends Controller
{
    public function index(Request $request)
    {
        $searchable = ['status'];
        $query = Loan::query();
        
        if ($request->boolean('trashed_only')) {
            $query->onlyTrashed();
        } elseif ($request->boolean('with_trashed')) {
            $query->withTrashed();
        }

        // ✅ FIXED: Removed redundant $query argument
        $query->applyControls($request, $searchable);

        if ($request->filled('shareholder_id')) {
            $query->where('shareholder_id', $request->shareholder_id);
        }

        return response()->json(Loan::getPaginatedResponse($query, $request));
    }

    public function indexRequests(Request $request)
    {
        $searchable = ['purpose', 'status', 'rejection_reason'];
        $query = LoanRequest::query();
        
        if ($request->boolean('trashed_only')) {
            $query->onlyTrashed();
        } elseif ($request->boolean('with_trashed')) {
            $query->withTrashed();
        }

        // ✅ FIXED: Removed redundant $query argument
        $query->applyControls($request, $searchable);
        
        if ($request->filled('shareholder_id')) {
            $query->where('shareholder_id', $request->shareholder_id);
        }

        return response()->json(LoanRequest::getPaginatedResponse($query, $request));
    }

    public function countRequests(Request $request)
    {
        $query = LoanRequest::query();
        if ($request->has('status')) {
            $query->where('status', $request->status);
        }
        return response()->json(['success' => true, 'count' => $query->count()]);
    }

    public function getTotalCapital()
    {
        // ✅ FIXED: Column name from share_capital to total_share_capital
        $total = Shareholder::sum('total_share_capital');
        return response()->json(['success' => true, 'total' => (float)$total]);
    }

    // ... keeping other methods but ensuring applyControls calls are fixed ...
    public function getMetrics(Request $request)
    {
        $periodExpr = DB::getDriverName() === 'pgsql' ? "TO_CHAR(date, 'Mon YY')" : "DATE_FORMAT(date, '%b %y')";

        $metrics = DB::table('transactions')
            ->select(
                DB::raw("$periodExpr as period"),
                DB::raw("SUM(CASE WHEN type = 'Capital Contribution' THEN amount ELSE 0 END) as share_capital"),
                DB::raw("SUM(CASE WHEN type = 'Loan Disbursement' THEN amount ELSE 0 END) as total_disbursed")
            )
            ->groupBy(DB::raw($periodExpr))
            ->orderBy(DB::raw("MIN(date)"), 'asc')
            ->get();

        return response()->json(['success' => true, 'data' => $metrics]);
    }

    public function getTotalDisbursed()
    {
        $total = Loan::sum('principal_amount');
        return response()->json(['success' => true, 'total' => (float)$total]);
    }

    public function getInterestRate()
    {
        return response()->json(['success' => true, 'rate' => 0.032]);
    }

    public function getActiveLoansCount()
    {
        $count = Loan::where('status', 'Active')->count();
        return response()->json(['success' => true, 'count' => $count]);
    }
}
