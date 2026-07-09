<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Loan;
use App\Models\Transaction;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class LoanController extends Controller
{
    public function index(Request $request)
    {
        $query = Loan::with('shareholder');

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        $loans = $query->latest()->paginate(10);

        return view('admin.loans.index', compact('loans'));
    }

    public function show(Loan $loan)
    {
        $loan->load(['shareholder', 'transactions', 'loanRequest']);
        return view('admin.loans.show', compact('loan'));
    }

    public function payment(Loan $loan)
    {
        $loan->load(['shareholder', 'loanRequest']);
        return view('admin.loans.payment', compact('loan'));
    }

    public function storePayment(Request $request, Loan $loan)
    {
        $request->validate([
            'amount' => 'required|numeric|min:0.01|max:' . ($loan->remaining_balance + 0.01),
            'method' => 'required|string'
        ]);

        DB::transaction(function () use ($request, $loan) {
            Transaction::create([
                'shareholder_id' => $loan->shareholder_id,
                'reference_id' => $loan->id,
                'amount' => $request->amount,
                'type' => 'Loan Payment',
                'method' => $request->method,
                'status' => 'completed',
                'date' => now(),
            ]);

            $loan->decrement('remaining_balance', $request->amount);

            if ($loan->remaining_balance <= 0) {
                $loan->update(['status' => 'closed', 'remaining_balance' => 0]);
            }
        });

        return redirect()->route('admin.loans.show', $loan)->with('success', 'Payment recorded successfully.');
    }
}
