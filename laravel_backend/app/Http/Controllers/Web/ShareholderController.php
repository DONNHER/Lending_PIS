<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Shareholder;
use App\Models\Transaction;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ShareholderController extends Controller
{
    public function index(Request $request)
    {
        $query = Shareholder::query();

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where('firstname', 'ilike', "%{$search}%")
                  ->orWhere('lastname', 'ilike', "%{$search}%")
                  ->orWhere('email', 'ilike', "%{$search}%");
        }

        $shareholders = $query->latest()->paginate(10);

        return view('admin.shareholders.index', compact('shareholders'));
    }

    public function create()
    {
        return view('admin.shareholders.create');
    }

    public function show(Shareholder $shareholder)
    {
        $shareholder->load(['loans', 'transactions']);
        return view('admin.shareholders.show', compact('shareholder'));
    }

    public function addCapital(Shareholder $shareholder)
    {
        return view('admin.shareholders.add-capital', compact('shareholder'));
    }

    public function storeCapital(Request $request, Shareholder $shareholder)
    {
        $request->validate([
            'amount' => 'required|numeric|min:1',
            'method' => 'required|string',
            'remarks' => 'nullable|string'
        ]);

        DB::transaction(function () use ($request, $shareholder) {
            Transaction::create([
                'shareholder_id' => $shareholder->id,
                'amount' => $request->amount,
                'type' => 'Share Capital Contribution',
                'method' => $request->method,
                'status' => 'completed',
                'description' => $request->remarks,
                'date' => now(),
            ]);

            $shareholder->increment('total_share_capital', $request->amount);
        });

        return redirect()->route('admin.shareholders.show', $shareholder)->with('success', 'Share capital added successfully.');
    }
}
