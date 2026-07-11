<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Transaction;
use Illuminate\Http\Request;

class TransactionController extends Controller
{
    public function index(Request $request)
    {
        $query = Transaction::with(['shareholder' => function($q) {
            $q->withTrashed();
        }]);

        // Basic Sorting
        $query->orderBy('date', 'desc');

        // Simple filtering
        if ($request->filled('shareholder_id')) {
            $query->where('shareholder_id', $request->shareholder_id);
        }

        // Search
        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function($q) use ($search) {
                $q->where('type', 'like', "%$search%")
                  ->orWhere('method', 'like', "%$search%")
                  ->orWhere('status', 'like', "%$search%")
                  ->orWhere('reference_id', 'like', "%$search%");
            });
        }

        $paginated = $query->paginate($request->get('per_page', 10));

        return response()->json([
            'success' => true,
            'data' => $paginated->items(),
            'meta' => [
                'total' => $paginated->total(),
                'current_page' => $paginated->currentPage(),
                'last_page' => $paginated->lastPage(),
            ]
        ]);
    }

    /**
     * Get transaction history for a specific reference (e.g. Loan History)
     */
    public function history($referenceId)
    {
        $transactions = Transaction::where('reference_id', $referenceId)
            ->with('shareholder')
            ->latest('date')
            ->get();
            
        return response()->json([
            'success' => true,
            'data' => $transactions
        ]);
    }

    public function count(Request $request)
    {
        $query = Transaction::query();

        $total = $query->count();
        $all = Transaction::all()->count();

        return response()->json([
            'success' => true,
            'total' => $total,
            'debug_all' => $all,
            'table' => (new Transaction)->getTable()
        ]);
    }

    public function getByShareholder($shareholderId)
    {
        $transactions = Transaction::where('shareholder_id', $shareholderId)->latest('date')->get();
        return response()->json(['success' => true, 'data' => $transactions]);
    }

    public function store(Request $request)
    {
        $transaction = Transaction::create($request->all());
        return response()->json(['success' => true, 'data' => $transaction], 201);
    }
}