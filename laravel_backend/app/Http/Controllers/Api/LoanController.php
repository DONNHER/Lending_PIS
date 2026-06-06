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

/**
 * Class LoanController
 * 
 * Manages loan lifecycles, including loan requests, disbursement tracking,
 * and lending metrics. It supports advanced filtering, soft deletes, 
 * and optimistic locking.
 * 
 * @package App\Http\Controllers\Api
 */
class LoanController extends Controller
{
    /**
     * Display a listing of loans with advanced controls.
     * Supports ?trashed_only=true and ?with_trashed=true.
     */
    public function index(Request $request)
    {
        $searchable = ['status'];
        
        $query = Loan::query();
        if ($request->boolean('trashed_only')) {
            $query->onlyTrashed();
        } elseif ($request->boolean('with_trashed')) {
            $query->withTrashed();
        }

        $query = Loan::applyControls($query, $request, $searchable);

        if ($request->filled('shareholder_id')) {
            $query->where('shareholder_id', $request->shareholder_id);
        }

        return response()->json(Loan::getPaginatedResponse($query, $request));
    }

    /**
     * READ: Detail view with audit trail.
     * Returns the loan record and the last 20 related activity log entries.
     */
    public function show($id)
    {
        $loan = Loan::withTrashed()->with(['shareholder', 'loanRequest'])->find($id);
        if (!$loan) return response()->json(['success' => false, 'message' => 'Loan not found'], 404);
        
        $auditTrail = ActivityLog::where('description', 'like', "%loans (ID: {$id})%")
            ->latest('created_at')
            ->limit(20)
            ->get();

        return response()->json([
            'success' => true, 
            'data' => $loan,
            'audit_trail' => $auditTrail
        ]);
    }

    /**
     * UPDATE: Modifies loan details.
     * Implements Optimistic Locking via the 'version' field.
     */
    public function update(Request $request, $id)
    {
        $loan = Loan::findOrFail($id);

        $request->validate([
            'version' => 'required|integer',
        ]);

        try {
            $loan->version = $request->version;
            $loan->update($request->all());

            return response()->json([
                'success' => true, 
                'message' => 'Loan updated successfully', 
                'data' => $loan
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false, 
                'message' => $e->getMessage()
            ], 409);
        }
    }

    /**
     * DELETE: Soft delete a loan.
     * Includes a cascade warning if the loan is currently active.
     */
    public function destroy($id)
    {
        $loan = Loan::findOrFail($id);

        // Warning if loan is active
        if ($loan->status === 'Active' && !request()->boolean('force')) {
            return response()->json([
                'success' => false,
                'requires_confirmation' => true,
                'message' => 'This is an active loan with a remaining balance. Deleting it will affect financial tracking. Proceed?'
            ], 409);
        }

        $loan->delete();
        return response()->json(['success' => true, 'message' => 'Loan soft-deleted successfully']);
    }

    /**
     * Restore a soft-deleted loan.
     */
    public function restore($id)
    {
        $loan = Loan::onlyTrashed()->findOrFail($id);
        $loan->restore();

        return response()->json(['success' => true, 'message' => 'Loan restored successfully', 'data' => $loan]);
    }

    /**
     * Display a listing of loan requests with advanced controls.
     */
    public function indexRequests(Request $request)
    {
        $searchable = ['purpose', 'status', 'rejection_reason'];
        
        $query = LoanRequest::query();
        if ($request->boolean('trashed_only')) {
            $query->onlyTrashed();
        } elseif ($request->boolean('with_trashed')) {
            $query->withTrashed();
        }

        $query = LoanRequest::applyControls($query, $request, $searchable);
        
        if ($request->filled('shareholder_id')) {
            $query->where('shareholder_id', $request->shareholder_id);
        }

        return response()->json(LoanRequest::getPaginatedResponse($query, $request));
    }

    /**
     * Bulk Actions for Loans or Requests.
     * Supports: delete, restore, update_status, export.
     */
    public function bulkAction(Request $request)
    {
        $request->validate([
            'ids' => 'required|array',
            'action' => 'required|string|in:delete,restore,update_status,export',
            'target' => 'required|string|in:loans,requests',
            'status' => 'required_if:action,update_status'
        ]);

        $ids = $request->ids;
        $model = $request->target === 'loans' ? Loan::class : LoanRequest::class;

        switch ($request->action) {
            case 'delete':
                $model::whereIn('id', $ids)->delete();
                return response()->json(['success' => true, 'message' => count($ids) . ' items soft-deleted.']);
            
            case 'restore':
                $model::onlyTrashed()->whereIn('id', $ids)->restore();
                return response()->json(['success' => true, 'message' => count($ids) . ' items restored.']);

            case 'update_status':
                $model::whereIn('id', $ids)->update(['status' => $request->status]);
                return response()->json(['success' => true, 'message' => count($ids) . ' items updated.']);
            
            case 'export':
                return $this->export($request, $ids, $request->target);
        }
    }

    /**
     * Export selected records to CSV.
     */
    public function export(Request $request, $ids = null, $target = 'loans')
    {
        if ($target === 'loans') {
            $query = Loan::with('shareholder');
            $filename = 'loans_export_';
            $columns = ['ID', 'Shareholder', 'Principal', 'Interest Rate', 'Balance', 'Status', 'Due Date'];
        } else {
            $query = LoanRequest::with('shareholder');
            $filename = 'loan_requests_export_';
            $columns = ['ID', 'Shareholder', 'Amount', 'Purpose', 'Status', 'Created At'];
        }

        if ($ids) {
            $query->whereIn('id', $ids);
        } else {
            $query->applyControls($query, $request, ['status', 'purpose']);
        }

        $data = $query->get();
        $csvFileName = $filename . date('Ymd_His') . '.csv';
        
        $headers = [
            "Content-type"        => "text/csv",
            "Content-Disposition" => "attachment; filename=$csvFileName",
        ];

        $callback = function() use($data, $columns, $target) {
            $file = fopen('php://output', 'w');
            fputcsv($file, $columns);

            foreach ($data as $row) {
                if ($target === 'loans') {
                    fputcsv($file, [
                        $row->id,
                        $row->shareholder ? $row->shareholder->firstname . ' ' . $row->shareholder->lastname : 'N/A',
                        $row->principal_amount,
                        $row->interest_rate,
                        $row->remaining_balance,
                        $row->status,
                        $row->due_date
                    ]);
                } else {
                    fputcsv($file, [
                        $row->id,
                        $row->shareholder ? $row->shareholder->firstname . ' ' . $row->shareholder->lastname : 'N/A',
                        $row->amount,
                        $row->purpose,
                        $row->status,
                        $row->created_at
                    ]);
                }
            }
            fclose($file);
        };

        return response()->stream($callback, 200, $headers);
    }

    /**
     * Count total loan requests based on filter.
     */
    public function countRequests(Request $request)
    {
        $query = LoanRequest::query();
        if ($request->has('status')) {
            $query->where('status', $request->status);
        }
        return response()->json(['success' => true, 'count' => $query->count()]);
    }

    /**
     * Store a new loan request.
     */
    public function storeRequest(Request $request)
    {
        $loanRequest = LoanRequest::create($request->all());
        $loanRequest->load('shareholder');
        return response()->json([
            'success' => true, 
            'message' => 'Loan request submitted successfully', 
            'data' => $loanRequest
        ], 201);
    }

    /**
     * Update the status of a loan request (Approve/Reject).
     */
    public function updateRequestStatus(Request $request, $id)
    {
        $loanRequest = LoanRequest::findOrFail($id);
        $loanRequest->update(['status' => $request->status]);
        return response()->json([
            'success' => true, 
            'message' => 'Loan request status updated to ' . $request->status, 
            'data' => $loanRequest
        ]);
    }

    /**
     * Fetch all loans for a specific shareholder.
     */
    public function getByShareholder($shareholderId)
    {
        $loans = Loan::where('shareholder_id', $shareholderId)->latest()->get();
        return response()->json(['success' => true, 'data' => $loans]);
    }

    /**
     * Generate financial metrics for charting.
     */
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

    /**
     * Calculate total disbursed amount across all loans.
     */
    public function getTotalDisbursed()
    {
        $total = Loan::sum('principal_amount');
        return response()->json(['success' => true, 'total' => (float)$total]);
    }

    /**
     * Calculate total capital held by all shareholders.
     */
    public function getTotalCapital()
    {
        $total = Shareholder::sum('share_capital');
        return response()->json(['success' => true, 'total' => (float)$total]);
    }

    /**
     * Get the current system interest rate.
     */
    public function getInterestRate()
    {
        return response()->json(['success' => true, 'rate' => 0.032]);
    }

    /**
     * Count current active loans.
     */
    public function getActiveLoansCount()
    {
        $count = Loan::where('status', 'Active')->count();
        return response()->json(['success' => true, 'count' => $count]);
    }

    /**
     * Fetch interest rate change history.
     */
    public function getInterestRateHistory()
    {
        $history = [
            [
                'id' => 1,
                'rate' => 0.032,
                'effective_date' => now()->startOfYear()->toIso8601String(),
                'created_at' => now()->startOfYear()->toIso8601String()
            ]
        ];
        return response()->json(['success' => true, 'data' => $history]);
    }
}
