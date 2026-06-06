<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Transaction;
use Illuminate\Http\Request;

/**
 * Class TransactionController
 * 
 * Manages the financial ledger of the application. 
 * Provides endpoints for viewing, filtering, and exporting transactions.
 * 
 * @package App\Http\Controllers\Api
 */
class TransactionController extends Controller
{
    /**
     * Display a listing of transactions with advanced controls.
     * Supports filtering by type, shareholder, and date range.
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function index(Request $request)
    {
        $searchable = ['reference_id', 'type', 'method', 'status'];
        
        $query = Transaction::query();

        // Handle Soft Delete filters
        if ($request->boolean('trashed_only')) {
            $query->onlyTrashed();
        } elseif ($request->boolean('with_trashed')) {
            $query->withTrashed();
        }

        $query = Transaction::with('shareholder')->applyControls($query, $request, $searchable);

        // Filter by multiple types if provided
        if ($request->filled('types')) {
            $types = explode(',', $request->types);
            $query->whereIn('type', $types);
        }

        // Filter by specific shareholder
        if ($request->filled('shareholder_id')) {
            $query->where('shareholder_id', $request->shareholder_id);
        }

        return response()->json(Transaction::getPaginatedResponse($query, $request));
    }

    /**
     * Perform bulk operations on transaction records.
     * Supported actions: delete, restore, update_status, export.
     */
    public function bulkAction(Request $request)
    {
        $request->validate([
            'ids' => 'required|array',
            'action' => 'required|string|in:delete,restore,update_status,export',
            'status' => 'required_if:action,update_status'
        ]);

        $ids = $request->ids;

        switch ($request->action) {
            case 'delete':
                Transaction::whereIn('id', $ids)->delete();
                return response()->json(['success' => true, 'message' => count($ids) . ' transactions soft-deleted.']);
            
            case 'restore':
                Transaction::onlyTrashed()->whereIn('id', $ids)->restore();
                return response()->json(['success' => true, 'message' => count($ids) . ' transactions restored.']);

            case 'update_status':
                Transaction::whereIn('id', $ids)->update(['status' => $request->status]);
                return response()->json(['success' => true, 'message' => count($ids) . ' transactions updated.']);
            
            case 'export':
                return $this->export($request, $ids);
        }
    }

    /**
     * Export transaction records to a CSV file.
     */
    public function export(Request $request, $ids = null)
    {
        $query = Transaction::with('shareholder');
        if ($ids) {
            $query->whereIn('id', $ids);
        } else {
            $query = Transaction::applyControls($query, $request, ['reference_id', 'type']);
        }

        $data = $query->get();
        $filename = 'transactions_export_' . date('Ymd_His') . '.csv';
        
        $headers = [
            "Content-type"        => "text/csv",
            "Content-Disposition" => "attachment; filename=$filename",
        ];

        $columns = ['ID', 'Reference', 'Shareholder', 'Type', 'Method', 'Amount', 'Status', 'Date'];

        $callback = function() use($data, $columns) {
            $file = fopen('php://output', 'w');
            fputcsv($file, $columns);
            foreach ($data as $row) {
                fputcsv($file, [
                    $row->id,
                    $row->reference_id,
                    $row->shareholder ? $row->shareholder->firstname . ' ' . $row->shareholder->lastname : 'N/A',
                    $row->type,
                    $row->method,
                    $row->amount,
                    $row->status,
                    $row->date
                ]);
            }
            fclose($file);
        };

        return response()->stream($callback, 200, $headers);
    }

    /**
     * Get a count of transactions based on status and type filters.
     */
    public function count(Request $request)
    {
        $query = Transaction::query();
        if ($request->has('types')) {
            $types = explode(',', $request->types);
            $query->whereIn('type', $types);
        }
        if ($request->has('status') && $request->status !== 'All') {
            $query->where('status', $request->status);
        }
        return response()->json(['success' => true, 'total' => $query->count()]);
    }

    /**
     * Fetch all transactions for a specific shareholder.
     */
    public function getByShareholder($shareholderId)
    {
        $transactions = Transaction::where('shareholder_id', $shareholderId)
            ->latest('date')
            ->get();
        return response()->json(['success' => true, 'data' => $transactions]);
    }

    /**
     * Store a new transaction entry.
     */
    public function store(Request $request)
    {
        $transaction = Transaction::create($request->all());
        return response()->json(['success' => true, 'data' => $transaction], 201);
    }
}
