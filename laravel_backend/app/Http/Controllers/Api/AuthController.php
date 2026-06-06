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

/**
 * Class AuthController
 * 
 * Handles user authentication, registration, multi-factor authentication (MFA),
 * and password recovery processes.
 * 
 * @package App\Http\Controllers\Api
 */
class AuthController extends Controller
{
    /**
     * @var string Password security policy regex.
     */
    protected $passwordPolicy = 'required|string|min:8|regex:/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/';
    
    /**
     * @var string Human-readable password policy message.
     */
    protected $passwordPolicyMessage = 'Password must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, one number, and one special character.';

    /**
     * Helper to log authentication-related activities.
     */
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
    }

    /**
     * Handle user registration.
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function register(Request $request)
    {
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
            $user = User::create([
                'username' => $request->username,
                'email' => $request->email,
                'password' => Hash::make($request->password),
                'firstname' => $request->firstname,
                'lastname' => $request->lastname,
                'role' => $request->role,
                'status' => 'active',
                'avatar_url' => $request->avatar_url,
                'mfa_enabled' => true,
            ]);

            // Clear any existing tokens (prevent concurrent sessions)
            $user->tokens()->delete();
            $token = $user->createToken('auth_token')->plainTextToken;

            $this->logAuth($user, 'Register', $request);

            return response()->json(['success' => true, 'user' => $user, 'token' => $token], 201);
        } catch (\Exception $e) {
            Log::error('Registration failed: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Registration failed'], 500);
        }
    }

    /**
     * Handle user login with security checks (Lockout, MFA).
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function login(Request $request)
    {
        $request->validate(['email' => 'required|email', 'password' => 'required']);

        $user = User::where('email', $request->email)->first();

        // 1. Basic Existence Check
        if (!$user) {
            $this->logAuth(null, 'Login Failed', $request, true, "Attempted login with non-existent email: {$request->email}");
            return response()->json(['message' => 'Invalid credentials'], 401);
        }

        // 2. Account Lockout Check
        if ($user->isLocked()) {
            $this->logAuth($user, 'Login Attempt (Locked)', $request, true, "User attempted to login while account is locked.");
            $minutesLeft = now()->diffInMinutes($user->locked_until) + 1;
            return response()->json([
                'success' => false,
                'message' => "Account is temporarily locked. Please try again in $minutesLeft minutes."
            ], 423);
        }

        // 3. Status Check
        if (!$user->isActive()) {
            $this->logAuth($user, 'Login Attempt (Inactive)', $request, false, "Inactive user attempted login.");
            return response()->json([
                'success' => false,
                'message' => 'Your account is ' . $user->status . '. Please contact the administrator.'
            ], 403);
        }

        // 4. Password Verification
        if (!Hash::check($request->password, $user->password)) {
            $user->increment('failed_attempts');
            $this->logAuth($user, 'Login Failed', $request, false, "Invalid password attempt.");
            
            // Trigger Lockout if attempts exceed 5
            if ($user->failed_attempts >= 5) {
                $user->update(['locked_until' => now()->addMinutes(15), 'failed_attempts' => 0]);
                $this->logAuth($user, 'Account Locked', $request, true, "Account locked after 5 failed attempts.");
                return response()->json(['success' => false, 'message' => 'Too many failed attempts. Account locked for 15 minutes.'], 423);
            }
            return response()->json(['message' => 'Invalid credentials'], 401);
        }

        // Success: Reset failed attempts
        $user->update(['failed_attempts' => 0, 'locked_until' => null]);

        // 5. MFA Flow
        if ($user->mfa_enabled) {
            $code = rand(100000, 999999);
            $user->update(['mfa_code' => $code, 'mfa_expires_at' => now()->addMinutes(10)]);
            
            try {
                Mail::to($user->email)->send(new MfaCodeMail($user, $code));
            } catch (\Exception $e) {
                Log::error("MFA Email Error: " . $e->getMessage());
            }

            $this->logAuth($user, 'MFA Code Sent', $request);
            
            return response()->json([
                'success' => true,
                'mfa_required' => true,
                'email' => $user->email,
                'message' => 'MFA code sent to your email.'
            ]);
        }

        // Standard Login
        $user->tokens()->delete();
        $token = $user->createToken('auth_token')->plainTextToken;

        $this->logAuth($user, 'Login', $request);

        return response()->json(['success' => true, 'user' => $user, 'token' => $token]);
    }

    /**
     * Verify the 6-digit MFA code.
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function verifyMfa(Request $request)
    {
        $request->validate(['email' => 'required|email', 'code' => 'required|numeric']);
        $user = User::where('email', $request->email)->first();

        if (!$user || $user->mfa_code != $request->code || now()->isAfter($user->mfa_expires_at)) {
            $this->logAuth($user, 'MFA Failed', $request, true, "Invalid or expired MFA code provided.");
            return response()->json(['success' => false, 'message' => 'Invalid or expired MFA code.'], 401);
        }

        $user->update(['mfa_code' => null, 'mfa_expires_at' => null]);
        $user->tokens()->delete();
        $token = $user->createToken('auth_token')->plainTextToken;

        $this->logAuth($user, 'MFA Verified', $request);

        return response()->json(['success' => true, 'user' => $user, 'token' => $token]);
    }

    /**
     * Log the user out and revoke token.
     */
    public function logout(Request $request)
    {
        $user = $request->user();
        $this->logAuth($user, 'Logout', $request);
        $user->currentAccessToken()->delete();
        return response()->json(['success' => true, 'message' => 'Logged out']);
    }

    /**
     * Initiate password reset flow.
     */
    public function forgotPassword(Request $request)
    {
        $validator = Validator::make($request->all(), ['email' => 'required|email|exists:users,email']);
        if ($validator->fails()) return response()->json(['success' => false, 'message' => 'Email not found'], 404);

        $code = rand(100000, 999999);
        $user = User::where('email', $request->email)->first();
        $user->update(['mfa_code' => $code, 'mfa_expires_at' => now()->addMinutes(15)]);
        
        try {
            Mail::to($user->email)->send(new PasswordResetMail($user, $code));
            $this->logAuth($user, 'Password Reset Requested', $request);
        } catch (\Exception $e) {
            Log::error("Reset Email Error: " . $e->getMessage());
        }
        
        return response()->json(['success' => true, 'message' => 'Password reset code sent to your email']);
    }

    /**
     * Reset password using verification code.
     */
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
            $this->logAuth($user, 'Password Reset Failed', $request, true, "Invalid or expired reset code.");
            return response()->json(['success' => false, 'message' => 'Invalid or expired reset code.'], 401);
        }

        $user->update([
            'password' => Hash::make($request->password),
            'mfa_code' => null,
            'mfa_expires_at' => null,
            'failed_attempts' => 0,
            'locked_until' => null
        ]);

        $user->tokens()->delete();
        $this->logAuth($user, 'Password Reset Successful', $request);

        return response()->json(['success' => true, 'message' => 'Password has been reset successfully']);
    }
}
