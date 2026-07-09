<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\LoanRequest;
use App\Models\Shareholder;
use App\Models\InterestSetting;
use App\Models\Notification;
use Illuminate\Http\Request;

class ShareholderPortalController extends Controller
{
    public function showApplicationForm()
    {
        $shareholder = auth()->user()->shareholder;
        if (!$shareholder) abort(404);

        $otherShareholders = Shareholder::where('id', '!=', $shareholder->id)->get();
        $interestRate = InterestSetting::latest()->first()?->rate ?? 0;

        return view('shareholder.loan-application', compact('otherShareholders', 'interestRate'));
    }

    public function storeApplication(Request $request)
    {
        $shareholder = auth()->user()->shareholder;

        $request->validate([
            'amount' => 'required|numeric|min:500|max:10000',
            'months' => 'required|integer|in:1,2,3,4,5,6,12',
            'purpose' => 'required|string',
            'comakers' => 'required|array|min:2',
            'comakers.*' => 'required|exists:shareholders,id|different:shareholder_id',
        ]);

        $interestRate = InterestSetting::latest()->first()?->rate ?? 0;

        $loanRequest = LoanRequest::create([
            'shareholder_id' => $shareholder->id,
            'requested_amount' => $request->amount,
            'interest_rate' => $interestRate,
            'months' => $request->months,
            'purpose' => $request->purpose,
            'loan_comakers' => $request->comakers,
            'status' => 'pending',
        ]);

        // Notify Co-makers
        foreach ($request->comakers as $cmId) {
            $cm = Shareholder::find($cmId);
            if ($cm && $cm->user_id) {
                Notification::create([
                    'user_id' => $cm->user_id,
                    'title' => 'New Co-maker Request',
                    'content' => "{$shareholder->full_name} has requested you to be a co-maker for a loan of ₱" . number_format($request->amount, 2),
                    'category' => 'loan',
                    'metadata' => ['loan_request_id' => $loanRequest->id]
                ]);
            }
        }

        return redirect()->route('dashboard')->with('success', 'Your loan application has been submitted and is pending co-maker approval.');
    }

    public function comakerRequests()
    {
        $shareholder = auth()->user()->shareholder;
        if (!$shareholder) abort(404);

        // Find requests where this shareholder is in the comakers array
        $requests = LoanRequest::with('shareholder')
            ->whereJsonContains('loan_comakers', $shareholder->id)
            ->where('status', 'pending')
            ->latest()
            ->get();

        return view('shareholder.comaker-requests', compact('requests', 'shareholder'));
    }

    public function signComaker(Request $request, LoanRequest $loanRequest)
    {
        $shareholder = auth()->user()->shareholder;
        $request->validate(['decision' => 'required|in:approved,rejected']);

        $decisions = $loanRequest->comaker_decisions ?? [];
        $decisions[$shareholder->id] = $request->decision;

        $loanRequest->update(['comaker_decisions' => $decisions]);

        return back()->with('success', 'Your decision has been recorded.');
    }
}
