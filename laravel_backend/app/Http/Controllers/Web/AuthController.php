<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;

class AuthController extends Controller
{
    public function showLogin()
    {
        if (Auth::check()) {
            return redirect()->route('dashboard');
        }
        return view('auth.admin-login');
    }

    public function login(Request $request)
    {
        $credentials = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required'],
        ]);

        $user = User::where('email', $request->email)->first();

        if ($user && Hash::check($request->password, $user->password)) {
            if ($user->mfa_enabled) {
                // Generate and send code
                $code = str_pad(rand(0, 999999), 6, '0', STR_PAD_LEFT);
                $user->update([
                    'mfa_code' => $code,
                    'mfa_expires_at' => now()->addMinutes(10)
                ]);

                session(['mfa_user_id' => $user->id]);

                // In real app, send mail here. For refactor, we just store it.
                // Mail::to($user->email)->send(new MfaCodeMail($code));

                return redirect()->route('login.mfa');
            }

            Auth::login($user, $request->has('remember'));
            $request->session()->regenerate();
            return redirect()->intended('dashboard');
        }

        return back()->withErrors([
            'email' => 'The provided credentials do not match our records.',
        ])->onlyInput('email');
    }

    public function showMfa()
    {
        if (!session('mfa_user_id')) {
            return redirect()->route('login');
        }
        return view('auth.mfa');
    }

    public function verifyMfa(Request $request)
    {
        $request->validate(['code' => 'required|string']);
        $userId = session('mfa_user_id');

        if (!$userId) return redirect()->route('login');

        $user = User::findOrFail($userId);

        if ($user->mfa_code === $request->code && $user->mfa_expires_at->isFuture()) {
            $user->update(['mfa_code' => null, 'mfa_expires_at' => null]);
            Auth::login($user);
            session()->forget('mfa_user_id');
            $request->session()->regenerate();
            return redirect()->intended('dashboard');
        }

        return back()->withErrors(['code' => 'Invalid or expired verification code.']);
    }

    public function resendMfa()
    {
        $userId = session('mfa_user_id');
        if (!$userId) return redirect()->route('login');

        $user = User::findOrFail($userId);
        $code = str_pad(rand(0, 999999), 6, '0', STR_PAD_LEFT);
        $user->update([
            'mfa_code' => $code,
            'mfa_expires_at' => now()->addMinutes(10)
        ]);

        return back()->with('success', 'A new code has been sent to your email.');
    }

    public function logout(Request $request)
    {
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();
        return redirect('/login');
    }

    public function showRegister()
    {
        return view('auth.admin-register');
    }

    public function register(Request $request)
    {
        $request->validate([
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8',
            'firstname' => 'required|string|max:255',
            'lastname' => 'required|string|max:255',
            'role' => 'required|string|in:admin,cashier,shareholder,staff,member',
        ]);

        $roleMap = [
            'cashier' => User::ROLE_STAFF,
            'shareholder' => User::ROLE_MEMBER,
            'admin' => User::ROLE_ADMIN,
        ];

        $role = $roleMap[$request->role] ?? $request->role;

        User::create([
            'username' => strstr($request->email, '@', true) . rand(100, 999),
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'firstname' => $request->firstname,
            'lastname' => $request->lastname,
            'role' => $role,
            'status' => User::STATUS_ACTIVE,
        ]);

        return redirect()->route('dashboard')->with('success', 'User registered successfully.');
    }

    public function showForgotPassword()
    {
        return view('auth.forgot-password');
    }
}
