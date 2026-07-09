<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\ActivityLog;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Validation\ValidationException;
use App\Services\NotificationService;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    protected $passwordPolicy = 'required|string|min:8|regex:/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/';
    protected $passwordPolicyMessage = 'Password must be at least 8 characters long and contain uppercase, lowercase, numbers, and special characters.';

    private function logAuth($user, $action, $request, $isSuspicious = false, $description = null)
    {
        ActivityLog::create([
            'user_id' => $user ? $user->id : null,
            'action' => $action,
            'log_type' => ActivityLog::TYPE_AUTH,
            'description' => $description ?? "Auth action: $action",
            'ip_address' => $request->ip(),
            'device_info' => $request->userAgent(),
            'is_suspicious' => $isSuspicious
        ]);

        // Trigger Real-time Notifications for Security Events
        if ($user && $action === 'Login Success') {
            NotificationService::send($user->id, 'Successful Login', 'You have successfully logged into your account.', 'system', 'info');
        }

        if ($user && $isSuspicious) {
            NotificationService::send($user->id, 'Suspicious Activity', "Failed login attempt: $description", 'warning', 'high');

            // Alert Admin on repeated failures
            if (str_contains($description, 'Invalid password attempt')) {
                $recentFailures = ActivityLog::where('log_type', ActivityLog::TYPE_AUTH)
                    ->where('action', 'Login Failed')
                    ->where('ip_address', $request->ip())
                    ->where('created_at', '>', now()->subMinutes(30))
                    ->count();

                if ($recentFailures >= 3) {
                    $admin = User::where('role', User::ROLE_ADMIN)->first();
                    if ($admin) {
                        NotificationService::send(
                            $admin->id,
                            'SECURITY ALERT: Brute Force Attempt',
                            "Multiple failed login attempts detected from IP: {$request->ip()} for account: {$request->email}",
                            'security',
                            'emergency'
                        );
                    }
                }
            }
        }

        if ($user && $action === 'Account Locked') {
            NotificationService::send($user->id, 'SECURITY ALERT: Account Locked', "Your account has been locked due to too many failed attempts.", 'critical', 'emergency');
        }
    }

    public function showLogin()
    {
        if (Auth::check()) {
            return redirect()->route('dashboard');
        }
        return view('auth.admin-login');
    }

    public function login(Request $request)
    {
        $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required'],
        ]);

        $throttleKey = Str::transliterate(Str::lower($request->input('email')).'|'.$request->ip());

        if (RateLimiter::tooManyAttempts($throttleKey, 5)) {
            $this->logAuth(null, 'Account Locked', $request, true, "Multiple failed login attempts for {$request->email}");
            $seconds = RateLimiter::availableIn($throttleKey);
            throw ValidationException::withMessages([
                'email' => "Too many login attempts. Please try again in {$seconds} seconds.",
            ]);
        }

        $user = User::where('email', $request->email)->first();

        if ($user && Hash::check($request->password, $user->password)) {
            RateLimiter::clear($throttleKey);

            if ($user->mfa_enabled) {
                $code = str_pad(rand(0, 999999), 6, '0', STR_PAD_LEFT);
                $user->update([
                    'mfa_code' => $code,
                    'mfa_expires_at' => now()->addMinutes(10)
                ]);

                session(['mfa_user_id' => $user->id]);
                $this->logAuth($user, 'MFA Challenge', $request);
                return redirect()->route('login.mfa');
            }

            Auth::login($user, $request->has('remember'));
            $request->session()->regenerate();
            $this->logAuth($user, 'Login Success', $request);
            return redirect()->intended('dashboard');
        }

        RateLimiter::hit($throttleKey, 600);
        $this->logAuth($user, 'Login Failed', $request, true, "Invalid password attempt for {$request->email}");

        return back()->withErrors([
            'email' => 'The provided credentials do not match our records.',
        ])->onlyInput('email');
    }

    public function logout(Request $request)
    {
        $this->logAuth(Auth::user(), 'Logout', $request);
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();
        return redirect('/login');
    }

    public function showForgotPassword()
    {
        return view('auth.forgot-password');
    }

    public function sendResetLinkEmail(Request $request)
    {
        $request->validate(['email' => 'required|email']);
        $this->logAuth(User::where('email', $request->email)->first(), 'Password Reset Request', $request);
        return back()->with('status', 'If this email exists in our system, we have sent a reset link.');
    }

    public function showRegister()
    {
        return view('auth.admin-register');
    }

    public function register(Request $request)
    {
        $request->validate([
            'email' => 'required|string|email|max:255|unique:users',
            'password' => $this->passwordPolicy,
            'firstname' => 'required|string|max:255',
            'lastname' => 'required|string|max:255',
            'role' => 'required|string|in:admin,cashier,shareholder,staff,member',
        ], [
            'password.regex' => $this->passwordPolicyMessage
        ]);

        $roleMap = [
            'cashier' => User::ROLE_STAFF,
            'shareholder' => User::ROLE_MEMBER,
            'admin' => User::ROLE_ADMIN,
        ];

        $role = $roleMap[$request->role] ?? $request->role;

        $user = User::create([
            'username' => strstr($request->email, '@', true) . rand(100, 999),
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'firstname' => $request->firstname,
            'lastname' => $request->lastname,
            'role' => $role,
            'status' => User::STATUS_ACTIVE,
        ]);

        $this->logAuth(Auth::user(), 'Register User', $request, false, "Created new user: {$user->email} with role {$role}");

        return redirect()->route('dashboard')->with('success', 'User registered successfully.');
    }
}
