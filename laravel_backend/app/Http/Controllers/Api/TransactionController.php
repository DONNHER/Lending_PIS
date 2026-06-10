<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Transaction;
use Illuminate\Http\Request;

class TransactionController extends Controller
{
    public function index(Request $request)
    {
        $searchable = ['reference_id', 'type', 'method', 'status'];
        $query = Transaction::query();

        if ($request->boolean('trashed_only')) {
            $query->onlyTrashed();
        } elseif ($request->boolean('with_trashed')) {
            $query->withTrashed();
        }

        $query->with('shareholder')->applyControls($request, $searchable);

        if ($request->filled('types')) {
            $types = explode(',', $request->types);
            $query->whereIn('type', $types);
        }

        if ($request->filled('shareholder_id')) {
            $query->where('shareholder_id', $request->shareholder_id);
        }

        if ($request->filled('reference_id')) {
            $query->where('reference_id', $request->reference_id);
        }

        return response()->json(Transaction::getPaginatedResponse($query, $request));
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
        if ($request->has('types')) {
            $types = explode(',', $request->types);
            $query->whereIn('type', $types);
        }
        if ($request->has('status') && $request->status !== 'All') {
            $query->where('status', $request->status);
        }
        if ($request->has('reference_id')) {
            $query->where('reference_id', $request->reference_id);
        }
        return response()->json(['success' => true, 'total' => $query->count()]);
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
