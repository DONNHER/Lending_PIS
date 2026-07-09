<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Shareholder;
use App\Models\Loan;
use App\Models\Transaction;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class DashboardController extends Controller
{
    public function index()
    {
        $user = Auth::user();

        if ($user->isAdmin()) {
            $stats = [
                'total_shareholders' => Shareholder::count(),
                'active_loans' => Loan::where('status', 'active')->count(),
                'total_disbursed' => Loan::where('status', 'active')->sum('amount'),
                'recent_transactions' => Transaction::with('shareholder')->latest()->take(5)->get(),
            ];

            return view('dashboard', compact('user', 'stats'));
        }

        // Shareholder Dashboard
        $shareholder = $user->shareholder;

        if (!$shareholder) {
            // Fallback for users without shareholder record (e.g. staff/cashier)
            $stats = [
                'total_shareholders' => 0,
                'active_loans' => 0,
                'total_disbursed' => 0,
                'recent_transactions' => collect(),
            ];
            return view('dashboard', compact('user', 'stats'));
        }

        $activeLoans = $shareholder->loans()->where('status', 'active')->with('transactions')->get();
        $activeLoanBalance = $activeLoans->sum('amount');
        $recentTransactions = $shareholder->transactions()->latest('date')->take(5)->get();

        return view('shareholder.dashboard', compact('user', 'shareholder', 'activeLoans', 'activeLoanBalance', 'recentTransactions'));
    }
}
