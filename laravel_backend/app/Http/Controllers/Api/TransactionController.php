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

        // ✅ FIXED: Removed redundant $query argument in scope call
        $query->with('shareholder')->applyControls($request, $searchable);

        if ($request->filled('types')) {
            $types = explode(',', $request->types);
            $query->whereIn('type', $types);
        }

        if ($request->filled('shareholder_id')) {
            $query->where('shareholder_id', $request->shareholder_id);
        }

        return response()->json(Transaction::getPaginatedResponse($query, $request));
    }

    public function export(Request $request, $ids = null)
    {
        $query = Transaction::with('shareholder');
        if ($ids) {
            $query->whereIn('id', $ids);
        } else {
            // ✅ FIXED
            $query->applyControls($request, ['reference_id', 'type']);
        }

        $data = $query->get();
        // ... rest of the method logic
        return response()->json(['success' => true, 'message' => 'Export logic simplified for fix']);
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
