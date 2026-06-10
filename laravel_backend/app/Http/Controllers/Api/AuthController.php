<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\ActivityLog;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use App\Mail\MfaCodeMail;
use App\Mail\PasswordResetMail;
use App\Mail\WelcomeShareholderMail;

class AuthController extends Controller
{
    protected $passwordPolicy = 'required|string|min:8|regex:/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/';
    protected $passwordPolicyMessage = 'Password must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, one number, and one special character.';

    private function logAuth($user, $action, $request, $isSuspicious = false, $description = null)
    {
        try {
            ActivityLog::create([
                'user_id' => $user ? $user->id : null,
                'action' => $action,
                'log_type' => ActivityLog::TYPE_AUTH,
                'description' => $description ?? "Auth action: $action",
                'ip_address' => $request->ip(),
                'device_info' => $request->userAgent(),
                'is_suspicious' => $isSuspicious
            ]);
        } catch (\Exception $e) {
            Log::error("Failed to log auth activity: " . $e->getMessage());
        }
    }

    public function register(Request $request)
    {
        ini_set('max_execution_time', 120); 
        set_time_limit(120);

        $validator = Validator::make($request->all(), [
            'username' => 'required|string|unique:users',
            'email' => 'required|string|email|unique:users',
            'password' => $this->passwordPolicy,
            'firstname' => 'required|string',
            'lastname' => 'required|string',
            'role' => 'required|string',
            'avatar_url' => 'nullable|string',
        ], [
            'password.regex' => $this->passwordPolicyMessage
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'errors' => $validator->errors()], 422);
        }

        try {
            $code = rand(100000, 999999);
            $status = 'pending';

            $user = User::create([
                'username' => $request->username,
                'email' => $request->email,
                'password' => Hash::make($request->password),
                'firstname' => $request->firstname,
                'lastname' => $request->lastname,
                'role' => $request->role,
                'status' => $status,
                'avatar_url' => $request->avatar_url,
                'mfa_enabled' => false,
                'mfa_code' => $code,
                'mfa_expires_at' => now()->addMinutes(15),
            ]);

            try {
                if ($request->role === 'shareholder') {
                    Mail::to($user->email)->send(new WelcomeShareholderMail($user, $request->password));
                } else {
                    Mail::to($user->email)->send(new MfaCodeMail($user, $code));
                }
            } catch (\Exception $e) {
                Log::error("Registration Email Error: " . $e->getMessage());
            }

            $this->logAuth($user, 'Register (Pending)', $request);
            
            return response()->json([
                'success' => true, 
                'user' => $user,
                'mfa_required' => true,
                'email' => $user->email,
                'message' => 'Registration successful. Activation code sent.'
            ], 201);
        } catch (\Exception $e) {
            Log::error('Registration failed: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Registration failed'], 500);
        }
    }

    public function login(Request $request)
    {
        ini_set('max_execution_time', 120);
        set_time_limit(120);

        $request->validate(['email' => 'required|email', 'password' => 'required']);
        $user = User::where('email', $request->email)->first();

        if (!$user) {
            return response()->json(['message' => 'Invalid credentials'], 401);
        }

        if ($user->isLocked()) {
            $minutesLeft = now()->diffInMinutes($user->locked_until) + 1;
            return response()->json(['success' => false, 'message' => "Account locked. Try again in $minutesLeft mins."], 423);
        }

        if (!Hash::check($request->password, $user->password)) {
            $user->increment('failed_attempts');
            if ($user->failed_attempts >= 5) {
                $user->update(['locked_until' => now()->addMinutes(15), 'failed_attempts' => 0]);
                return response()->json(['success' => false, 'message' => 'Too many failed attempts.'], 423);
            }
            return response()->json(['message' => 'Invalid credentials'], 401);
        }

        $user->update(['failed_attempts' => 0, 'locked_until' => null]);

        // 🚀 BYPASS VERIFICATION FOR ACTIVE USERS
        if ($user->status === 'active') {
            $user->tokens()->delete();
            $token = $user->createToken('auth_token')->plainTextToken;
            return response()->json([
                'success' => true, 
                'user' => $user, 
                'token' => $token,
                'mfa_required' => false,
                'message' => 'Login successful.'
            ]);
        }

        // REQUIRE VERIFICATION FOR NON-ACTIVE ACCOUNTS (Pending, Inactive, etc.)
        $code = rand(100000, 999999);
        $user->update(['mfa_code' => $code, 'mfa_expires_at' => now()->addMinutes(10)]);
        
        try {
            Mail::to($user->email)->send(new MfaCodeMail($user, $code));
        } catch (\Exception $e) {
            Log::error("MFA Email Error: " . $e->getMessage());
        }

        return response()->json([
            'success' => true,
            'mfa_required' => true,
            'user' => $user,
            'email' => $user->email,
            'message' => 'Verification code sent to your email.'
        ]);
    }

    public function verifyMfa(Request $request)
    {
        $request->validate(['email' => 'required|email', 'code' => 'required|numeric']);
        $user = User::where('email', $request->email)->first();

        if (!$user || $user->mfa_code != $request->code || now()->isAfter($user->mfa_expires_at)) {
            return response()->json(['success' => false, 'message' => 'Invalid or expired code.'], 401);
        }

        $user->update([
            'mfa_code' => null, 
            'mfa_expires_at' => null,
            'status' => 'active'
        ]);
        
        $user->tokens()->delete();
        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json(['success' => true, 'user' => $user, 'token' => $token]);
    }

    public function resendMfa(Request $request)
    {
        $request->validate(['email' => 'required|email']);
        $user = User::where('email', $request->email)->first();
        if (!$user) return response()->json(['success' => false, 'message' => 'User not found.'], 404);

        $code = rand(100000, 999999);
        $user->update(['mfa_code' => $code, 'mfa_expires_at' => now()->addMinutes(15)]);

        try {
            Mail::to($user->email)->send(new MfaCodeMail($user, $code));
            return response()->json(['success' => true, 'message' => 'Verification code resent.']);
        } catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => 'Email failed'], 500);
        }
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();
        return response()->json(['success' => true, 'message' => 'Logged out']);
    }

    public function updateProfile(Request $request)
    {
        $user = $request->user();
        $validator = Validator::make($request->all(), [
            'firstname' => 'required|string|max:255',
            'lastname' => 'required|string|max:255',
            'avatar_url' => 'nullable|string',
        ]);

        if ($validator->fails()) return response()->json(['success' => false, 'errors' => $validator->errors()], 422);

        $user->update($request->only('firstname', 'lastname', 'avatar_url'));
        return response()->json(['success' => true, 'user' => $user]);
    }

    public function changePassword(Request $request)
    {
        $user = $request->user();
        $validator = Validator::make($request->all(), [
            'current_password' => 'required|string',
            'new_password' => $this->passwordPolicy . '|confirmed',
        ]);

        if ($validator->fails()) return response()->json(['success' => false, 'errors' => $validator->errors()], 422);

        if (!Hash::check($request->current_password, $user->password)) {
            return response()->json(['success' => false, 'message' => 'Incorrect password.'], 401);
        }

        $user->update(['password' => Hash::make($request->new_password)]);
        return response()->json(['success' => true, 'message' => 'Password updated.']);
    }

    public function forgotPassword(Request $request)
    {
        $validator = Validator::make($request->all(), ['email' => 'required|email|exists:users,email']);
        if ($validator->fails()) return response()->json(['success' => false, 'message' => 'Email not found'], 404);

        $code = rand(100000, 999999);
        $user = User::where('email', $request->email)->first();
        $user->update(['mfa_code' => $code, 'mfa_expires_at' => now()->addMinutes(15)]);
        
        try {
            Mail::to($user->email)->send(new PasswordResetMail($user, $code));
            return response()->json(['success' => true, 'message' => 'Reset code sent.']);
        } catch (\Exception $e) {
            return response()->json(['success' => true, 'message' => "Reset code: $code"]);
        }
    }

    public function resetPassword(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email|exists:users,email',
            'code' => 'required',
            'password' => $this->passwordPolicy . '|confirmed',
        ]);

        if ($validator->fails()) return response()->json(['success' => false, 'errors' => $validator->errors()], 422);

        $user = User::where('email', $request->email)->first();
        if ($user->mfa_code != $request->code || now()->isAfter($user->mfa_expires_at)) {
            return response()->json(['success' => false, 'message' => 'Invalid code.'], 401);
        }

        $user->update(['password' => Hash::make($request->password), 'mfa_code' => null, 'mfa_expires_at' => null]);
        $user->tokens()->delete();
        return response()->json(['success' => true, 'message' => 'Reset successful.']);
    }
}
