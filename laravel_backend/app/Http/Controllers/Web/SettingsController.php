<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\InterestSetting;
use Illuminate\Http\Request;

class SettingsController extends Controller
{
    public function index()
    {
        $interestRate = InterestSetting::latest()->first();
        return view('admin.settings.index', compact('interestRate'));
    }

    public function updateInterest(Request $request)
    {
        $request->validate([
            'rate' => 'required|numeric|min:0|max:100',
            'effective_date' => 'required|date'
        ]);

        InterestSetting::create([
            'rate' => $request->rate,
            'effective_date' => $request->effective_date,
            'updated_by' => auth()->id()
        ]);

        return back()->with('success', 'Interest rate updated successfully.');
    }
}
