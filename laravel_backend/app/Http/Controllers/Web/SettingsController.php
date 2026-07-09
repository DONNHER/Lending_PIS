<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\InterestSetting;
use App\Models\SiteSetting;
use Illuminate\Http\Request;

class SettingsController extends Controller
{
    public function index()
    {
        $interestRate = InterestSetting::latest()->first();

        $settings = [
            'branding' => SiteSetting::where('group', 'branding')->pluck('value', 'key'),
            'security' => SiteSetting::where('group', 'security')->pluck('value', 'key'),
            'backup' => SiteSetting::where('group', 'backup')->pluck('value', 'key'),
            'email' => SiteSetting::where('group', 'email')->pluck('value', 'key'),
            'maintenance' => SiteSetting::where('group', 'maintenance')->pluck('value', 'key'),
        ];

        return view('admin.settings.index', compact('interestRate', 'settings'));
    }

    public function updateGeneral(Request $request)
    {
        $group = $request->get('group', 'general');
        $inputs = $request->except(['_token', 'group']);

        foreach ($inputs as $key => $value) {
            $type = 'string';
            if (is_numeric($value)) $type = 'integer';
            if (in_array($key, ['mfa_required', 'maintenance_mode'])) $type = 'boolean';

            SiteSetting::set($key, $value, $type, $group);
        }

        return back()->with('success', ucfirst($group) . ' settings updated successfully.');
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
