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

        // Example of passing data directly to front end
        $stats = [
            'total_shareholders' => Shareholder::count(),
            'active_loans' => Loan::where('status', 'active')->count(),
            'total_disbursed' => Loan::where('status', 'active')->sum('amount'),
            'recent_transactions' => Transaction::with('shareholder')->latest()->take(5)->get(),
        ];

        return view('dashboard', compact('user', 'stats'));
    }
}
