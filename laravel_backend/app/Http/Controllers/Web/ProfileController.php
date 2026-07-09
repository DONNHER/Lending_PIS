<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rules\Password;

class ProfileController extends Controller
{
    protected $passwordPolicy = 'required|string|min:8|regex:/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/';
    protected $passwordPolicyMessage = 'Password must be at least 8 characters long and contain uppercase, lowercase, numbers, and special characters.';

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
            'contact_number' => ['nullable', 'string', 'regex:/^(09|\+639)\d{9}$/'],
            'avatar' => 'nullable|image|mimes:jpg,jpeg,png|max:2048|dimensions:min_width=100,min_height=100,max_width=1000,max_height=1000',
            'version' => 'required|integer'
        ], [
            'contact_number.regex' => 'The phone number must be a valid Philippine mobile number (e.g., 09123456789).',
            'avatar.dimensions' => 'The profile picture must be between 100x100 and 1000x1000 pixels.',
        ]);

        try {
            $data = [
                'firstname' => $request->firstname,
                'lastname' => $request->lastname,
                'version' => $request->version
            ];

            if ($request->hasFile('avatar')) {
                $path = $request->file('avatar')->store('avatars', 'public');
                $data['avatar_url'] = Storage::url($path);
            }

            $user->update($data);

            if ($user->shareholder) {
                $user->shareholder->update([
                    'first_name' => $request->firstname,
                    'last_name' => $request->lastname,
                    'full_name' => $request->firstname . ' ' . $request->lastname,
                    'address' => $request->address,
                    'contact_number' => $request->contact_number,
                    'version' => $request->shareholder_version ?? $user->shareholder->version
                ]);
            }

            return back()->with('success', 'Profile updated successfully.');
        } catch (\Exception $e) {
            return back()->with('error', $e->getMessage());
        }
    }

    public function updatePassword(Request $request)
    {
        $request->validate([
            'current_password' => 'required|current_password',
            'password' => ['required', 'confirmed', 'string', 'min:8', 'regex:/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/'],
        ], [
            'password.regex' => $this->passwordPolicyMessage
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
