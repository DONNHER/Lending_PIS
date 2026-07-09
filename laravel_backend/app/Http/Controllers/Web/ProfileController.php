<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;

class ProfileController extends Controller
{
    public function show()
    {
        $user = auth()->user();
        $user->load('shareholder');
        return view('profile.show', compact('user'));
    }

    public function update(Request $request)
    {
        $user = auth()->user();

        $request->validate([
            'firstname' => 'required|string|max:255',
            'lastname' => 'required|string|max:255',
            'address' => 'nullable|string|max:500',
            'contact_number' => 'nullable|string|max:20',
        ]);

        $user->update([
            'firstname' => $request->firstname,
            'lastname' => $request->lastname,
        ]);

        if ($user->shareholder) {
            $user->shareholder->update([
                'first_name' => $request->firstname,
                'last_name' => $request->lastname,
                'full_name' => $request->firstname . ' ' . $request->lastname,
                'address' => $request->address,
                'contact_number' => $request->contact_number,
            ]);
        }

        return back()->with('success', 'Profile updated successfully.');
    }

    public function updatePassword(Request $request)
    {
        $request->validate([
            'current_password' => 'required|current_password',
            'password' => ['required', 'confirmed', Password::min(8)],
        ]);

        $request->user()->update([
            'password' => Hash::make($request->password),
        ]);

        return back()->with('success', 'Password updated successfully.');
    }

    public function toggleMfa(Request $request)
    {
        $user = auth()->user();
        $user->update([
            'mfa_enabled' => !$user->mfa_enabled
        ]);

        $status = $user->mfa_enabled ? 'enabled' : 'disabled';
        return back()->with('success', "Two-factor authentication has been {$status}.");
    }
}
