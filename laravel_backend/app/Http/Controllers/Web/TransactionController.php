<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Transaction;
use Illuminate\Http\Request;

class TransactionController extends Controller
{
    public function index(Request $request)
    {
        $query = Transaction::with('shareholder');

        if ($request->filled('type')) {
            $query->where('type', $request->type);
        }

        $transactions = $query->latest('date')->paginate(15);

        return view('admin.transactions.index', compact('transactions'));
    }
}
