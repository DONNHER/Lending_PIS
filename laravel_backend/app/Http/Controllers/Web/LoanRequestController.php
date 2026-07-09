<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\LoanRequest;
use App\Models\Loan;
use App\Models\Shareholder;
use App\Models\InterestSetting;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class LoanRequestController extends Controller
{
    public function index()
    {
        $requests = LoanRequest::with('shareholder')->where('status', 'pending')->latest()->paginate(10);
        return view('admin.loan-requests.index', compact('requests'));
    }

    public function create()
    {
        $shareholders = Shareholder::all();
        $interestRate = InterestSetting::latest()->first()?->rate ?? 0;
        return view('admin.loan-requests.create', compact('shareholders', 'interestRate'));
    }

    public function store(Request $request)
    {
        $request->validate([
            'shareholder_id' => 'required|exists:shareholders,id',
            'amount' => 'required|numeric|min:500|max:10000',
            'months' => 'required|integer|in:1,2,3,4,5,6,12',
            'purpose' => 'required|string',
            'comakers' => 'required|array|min:2',
            'comakers.*' => 'required|exists:shareholders,id|different:shareholder_id',
        ]);

        $interestRate = InterestSetting::latest()->first()?->rate ?? 0;

        LoanRequest::create([
            'shareholder_id' => $request->shareholder_id,
            'requested_amount' => $request->amount,
            'interest_rate' => $interestRate,
            'months' => $request->months,
            'purpose' => $request->purpose,
            'loan_comakers' => $request->comakers,
            'status' => 'pending',
        ]);

        return redirect()->route('admin.loan-requests.index')->with('success', 'Loan request submitted successfully.');
    }

    public function show(LoanRequest $loanRequest)
    {
        $loanRequest->load('shareholder');
        return view('admin.loan-requests.show', compact('loanRequest'));
    }

    public function updateStatus(Request $request, LoanRequest $loanRequest)
    {
        $request->validate([
            'status' => 'required|in:approved,rejected',
            'remarks' => 'nullable|string'
        ]);

        DB::transaction(function () use ($request, $loanRequest) {
            $loanRequest->update([
                'status' => $request->status,
                'rejection_reason' => $request->remarks,
                'reviewed_at' => now(),
                'reviewed_by' => auth()->id()
            ]);

            if ($request->status === 'approved') {
                $totalInterest = ($loanRequest->requested_amount * ($loanRequest->interest_rate / 100)) * $loanRequest->months;
                $totalRepayable = $loanRequest->requested_amount + $totalInterest;

                Loan::create([
                    'shareholder_id' => $loanRequest->shareholder_id,
                    'loan_request_id' => $loanRequest->id,
                    'principal_amount' => $loanRequest->requested_amount,
                    'interest_rate' => $loanRequest->interest_rate,
                    'tenure_months' => $loanRequest->months,
                    'total_repayable' => $totalRepayable,
                    'remaining_balance' => $totalRepayable,
                    'monthly_amortization' => $totalRepayable / $loanRequest->months,
                    'processing_fee' => $loanRequest->requested_amount * 0.05,
                    'status' => 'active',
                    'release_date' => now(),
                    'next_repayment_date' => now()->addMonth(),
                ]);
            }
        });

        return redirect()->route('admin.loan-requests.index')->with('success', 'Loan request ' . $request->status);
    }
}
