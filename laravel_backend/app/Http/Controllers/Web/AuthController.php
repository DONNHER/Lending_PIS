<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

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

        if (Auth::attempt($credentials, $request->has('remember'))) {
            $request->session()->regenerate();
            return redirect()->intended('dashboard');
        }

        return back()->withErrors([
            'email' => 'The provided credentials do not match our records.',
        ])->onlyInput('email');
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

        // Map roles to model constants if necessary
        $roleMap = [
            'cashier' => User::ROLE_STAFF,
            'shareholder' => User::ROLE_MEMBER,
            'admin' => User::ROLE_ADMIN,
        ];

        $role = $roleMap[$request->role] ?? $request->role;

        User::create([
            'username' => strstr($request->email, '@', true) . rand(100, 999), // Generate a username
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
