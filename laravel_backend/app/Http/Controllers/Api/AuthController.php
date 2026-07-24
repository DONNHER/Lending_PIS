<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\ActivityLog;
use App\Models\Notification;
use App\Models\Shareholder;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;

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

    private function notifyPasswordChange($user)
    {
        try {
            Notification::create([
                'user_id' => $user->id,
                'shareholder_id' => $user->shareholder ? $user->shareholder->id : null,
                'title' => 'Security Alert: Password Changed',
                'content' => 'Your account password has been successfully updated. If you did not make this change, please contact support immediately.',
                'category' => 'security',
                'type' => 'alert',
                'is_unread' => true,
            ]);
        } catch (\Exception $e) {
            Log::error("Failed to create password change notification: " . $e->getMessage());
        }
    }

    public function register(Request $request)
    {
        Log::info('Laravel Register Attempt initiated', [
            'email' => $request->input('email'),
            'username' => $request->input('username'),
            'ip' => $request->ip()
        ]);

        $validator = Validator::make($request->all(), [
            'username' => 'required|string|unique:users',
            'email' => 'required|string|email|unique:users',
            'password' => $this->passwordPolicy,
            'firstname' => 'required|string',
            'lastname' => 'required|string',
            'role' => 'required|string',
            'avatar_url' => 'nullable|string',
            'address' => 'nullable|string',
            'phone' => 'nullable|string',
            'id_image_url' => 'nullable|string',
        ], [
            'password.regex' => $this->passwordPolicyMessage
        ]);

        if ($validator->fails()) {
            Log::warning('Laravel Register Validation Failed', ['errors' => $validator->errors()->toArray()]);
            return response()->json(['success' => false, 'errors' => $validator->errors()], 422);
        }

        try {
            return DB::transaction(function () use ($request) {
                $user = User::create([
                    'username' => $request->username,
                    'email' => $request->email,
                    'password' => Hash::make($request->password),
                    'firstname' => $request->firstname,
                    'lastname' => $request->lastname,
                    'role' => $request->role,
                    'status' => 'pending',
                    'avatar_url' => $request->avatar_url,
                    'address' => $request->address,
                ]);

                // 🚀 AUTOMATICALLY CREATE SHAREHOLDER RECORD
                if ($user->role === 'shareholder') {
                    Shareholder::create([
                        'user_id' => $user->id,
                        'email' => $user->email,
                        'first_name' => $user->firstname,
                        'last_name' => $user->lastname,
                        'full_name' => $user->firstname . ' ' . $user->lastname,
                        'address' => $user->address,
                        'contact_number' => $request->phone ?? '',
                        'total_share_capital' => $request->input('initial_share', 0.00),
                        'creditscore' => 700,
                        'status' => 'active',
                        'id_image_url' => $request->id_image_url,
                    ]);
                }

                $this->logAuth($user, 'Register (Pending)', $request);

                Log::info('Laravel Register Successful', ['user_id' => $user->id, 'email' => $user->email]);

                return response()->json([
                    'success' => true,
                    'user' => $user->load('shareholder'),
                    'mfa_required' => true,
                    'email' => $user->email,
                    'message' => 'Registration successful. Please verify the code sent to your email.'
                ], 201);
            });
        } catch (\Exception $e) {
            Log::error('Registration failed: ' . $e->getMessage(), ['trace' => $e->getTraceAsString()]);
            return response()->json([
                'success' => false,
                'message' => 'Registration failed: ' . $e->getMessage()
            ], 500);
        }
    }

    public function resetPassword(Request $request)
    {
        Log::info('Laravel Password Reset Attempt initiated', [
            'email' => $request->input('email'),
            'ip' => $request->ip(),
        ]);

        $validator = Validator::make($request->all(), [
            'email' => 'required|email|exists:users,email',
            'password' => $this->passwordPolicy,
        ], [
            'password.regex' => $this->passwordPolicyMessage
        ]);

        if ($validator->fails()) {
            Log::warning('Laravel Password Reset Validation Failed', ['errors' => $validator->errors()->toArray()]);
            return response()->json(['success' => false, 'errors' => $validator->errors()], 422);
        }

        try {
            $user = User::where('email', $request->email)->first();

            if (!$user) {
                Log::warning('Laravel Password Reset Failed: User not found', ['email' => $request->email]);
                return response()->json(['success' => false, 'message' => 'User not found.'], 404);
            }

            $user->update([
                'password' => Hash::make($request->password)
            ]);

            $this->logAuth($user, 'Password Reset Completed', $request);
            $this->notifyPasswordChange($user);

            Log::info('Laravel Password Reset Successful', ['user_id' => $user->id]);

            return response()->json([
                'success' => true,
                'message' => 'Password has been successfully synchronized and updated.'
            ]);
        } catch (\Exception $e) {
            Log::error('Password reset sync failed: ' . $e->getMessage(), ['trace' => $e->getTraceAsString()]);
            return response()->json([
                'success' => false,
                'message' => 'Failed to sync password: ' . $e->getMessage()
            ], 500);
        }
    }

    public function login(Request $request)
    {
        Log::info('Laravel Login Attempt initiated', [
            'email' => $request->input('email'),
            'ip' => $request->ip(),
            'user_agent' => $request->userAgent()
        ]);

        $request->validate(['email' => 'required|email', 'password' => 'required']);
        $user = User::where('email', $request->email)->first();

        if (!$user) {
            Log::warning('Laravel Login Failed: Email does not exist in local database', [
                'email' => $request->input('email')
            ]);
            return response()->json(['message' => 'Invalid credentials'], 401);
        }

        // 🚀 1. Check if account is locked
        if ($user->isLocked()) {
            $minutes = now()->diffInMinutes($user->locked_until);
            Log::warning('Laravel Login Blocked: Account is locked', [
                'email' => $user->email,
                'locked_until' => $user->locked_until
            ]);
            return response()->json([
                'success' => false,
                'message' => "Account is locked due to multiple failed attempts. Please try again in $minutes minutes."
            ], 403);
        }

        // 🚀 2. CAPTCHA Validation (If required)
        if ($user->failed_attempts >= 3) {
            if (!$request->has('captcha_token') || $request->captcha_token !== 'verified') {
                Log::info('Laravel Login Blocked: CAPTCHA required', ['email' => $user->email, 'failed_attempts' => $user->failed_attempts]);
                return response()->json([
                    'success' => false,
                    'captcha_required' => true,
                    'message' => 'Security check required. Please complete the CAPTCHA.'
                ], 403);
            }
        }

        // 🚀 3. Authenticate
        if (!Hash::check($request->password, $user->password)) {
            User::withoutEvents(function () use ($user, $request) {
                $user->increment('failed_attempts');

                if ($user->failed_attempts >= 5) {
                    $user->update(['locked_until' => now()->addMinutes(15)]);

                    ActivityLog::create([
                        'user_id' => $user->id,
                        'action' => 'Account Locked',
                        'log_type' => ActivityLog::TYPE_ERROR,
                        'description' => "Account locked for 15 minutes after 5 failed attempts from IP: {$request->ip()}",
                        'ip_address' => $request->ip(),
                        'is_suspicious' => true
                    ]);

                    Log::warning("Account locked: {$user->email} due to 5 consecutive failed attempts.");
                }
            });

            Log::warning('Laravel Login Failed: Password hash mismatch', [
                'email' => $user->email,
                'current_failed_attempts' => $user->failed_attempts
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Invalid credentials',
                'failed_attempts' => $user->failed_attempts,
                'captcha_required' => $user->failed_attempts >= 3
            ], 401);
        }

        $user->refresh();

        User::withoutEvents(function () use ($user) {
            $user->update(['failed_attempts' => 0, 'locked_until' => null]);
        });

        if ($user->status === 'active') {
            $token = $user->createToken('auth_token')->plainTextToken;
            $this->logAuth($user, 'User Login', $request);

            Log::info('Laravel Login Successful (Active User)', [
                'user_id' => $user->id,
                'email' => $user->email,
                'role' => $user->role
            ]);

            return response()->json([
                'success' => true,
                'user' => $user->load('shareholder'),
                'token' => $token,
                'mfa_required' => false
            ]);
        }

        Log::info('Laravel Login Successful, but Pending Verification (MFA Required)', [
            'user_id' => $user->id,
            'email' => $user->email
        ]);

        return response()->json([
            'success' => true,
            'user' => $user->load('shareholder'),
            'mfa_required' => true,
            'email' => $user->email,
            'message' => 'Verification required.'
        ]);
    }

    public function updateProfile(Request $request)
    {
        $user = $request->user();

        $validator = Validator::make($request->all(), [
            'firstname' => 'sometimes|string|max:255',
            'lastname' => 'sometimes|string|max:255',
            'address' => 'nullable|string',
            'avatar_url' => 'nullable|string',
            'id_image_url' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            Log::warning('Laravel Profile Update Validation Failed', ['errors' => $validator->errors()->toArray()]);
            return response()->json(['success' => false, 'errors' => $validator->errors()], 422);
        }

        try {
            $user->update($request->only([
                'firstname',
                'lastname',
                'avatar_url',
                'address',
            ]));

            if ($user->shareholder) {
                $user->shareholder->update([
                    'first_name' => $user->firstname,
                    'last_name' => $user->lastname,
                    'full_name' => $user->firstname . ' ' . $user->lastname,
                    'address' => $user->address,
                    'id_image_url' => $request->has('id_image_url') ? $request->id_image_url : $user->shareholder->id_image_url,
                ]);
            }

            Log::info('Laravel Profile Update Successful', ['user_id' => $user->id]);

            return response()->json([
                'success' => true,
                'user' => $user->load('shareholder'),
                'message' => 'Profile updated successfully'
            ]);
        } catch (\Exception $e) {
            Log::error('Profile update failed: ' . $e->getMessage(), ['trace' => $e->getTraceAsString()]);
            return response()->json(['success' => false, 'message' => 'Failed to update profile'], 500);
        }
    }

    public function changePassword(Request $request)
    {
        $user = $request->user();

        $validator = Validator::make($request->all(), [
            'current_password' => 'required|string',
            'new_password' => $this->passwordPolicy,
        ], [
            'new_password.regex' => $this->passwordPolicyMessage
        ]);

        if ($validator->fails()) {
            Log::warning('Laravel Change Password Validation Failed', ['errors' => $validator->errors()->toArray()]);
            return response()->json(['success' => false, 'errors' => $validator->errors()], 422);
        }

        if (!Hash::check($request->current_password, $user->password)) {
            Log::warning('Laravel Change Password Failed: Current password mismatch', ['user_id' => $user->id]);
            return response()->json(['success' => false, 'message' => 'Current password does not match'], 400);
        }

        try {
            $user->update([
                'password' => Hash::make($request->new_password)
            ]);

            $this->notifyPasswordChange($user);

            Log::info('Laravel Change Password Successful', ['user_id' => $user->id]);

            return response()->json(['success' => true, 'message' => 'Password changed successfully']);
        } catch (\Exception $e) {
            Log::error('Password change failed: ' . $e->getMessage(), ['trace' => $e->getTraceAsString()]);
            return response()->json(['success' => false, 'message' => 'Failed to change password'], 500);
        }
    }

    public function forgotPassword(Request $request)
    {
        $request->validate([
            'email' => 'required|email'
        ]);

        $user = User::where('email', $request->email)->first();

        if (!$user) {
            Log::warning('Laravel Forgot Password Failed: Email not found', ['email' => $request->input('email')]);
            return response()->json([
                'success' => false,
                'message' => 'No, this email is not registered in our system.'
            ], 404);
        }

        $this->logAuth($user, 'Password Reset Request', $request);

        return response()->json([
            'success' => true,
            'message' => 'Password reset is handled by Supabase. Please use the Supabase reset password flow.'
        ]);
    }

    public function verifyMfa(Request $request)
    {
        $request->validate(['email' => 'required|email']);
        $user = User::where('email', $request->email)->first();

        if (!$user) {
            Log::warning('Laravel Verify MFA Failed: User not found', ['email' => $request->input('email')]);
            return response()->json(['success' => false, 'message' => 'User not found.'], 404);
        }

        $user->update(['status' => 'active']);

        $user->tokens()->delete();
        $token = $user->createToken('auth_token')->plainTextToken;

        Log::info('Laravel Verify MFA Successful', ['user_id' => $user->id]);

        return response()->json(['success' => true, 'user' => $user->load('shareholder'), 'token' => $token]);
    }

    public function resendMfa(Request $request)
    {
        $request->validate(['email' => 'required|email']);
        Log::info("MFA Resend requested for: " . $request->email);
        return response()->json(['success' => true, 'message' => 'Delivery is handled by Supabase.']);
    }

    public function logout(Request $request)
    {
        $user = $request->user();
        if ($user) {
            $this->logAuth($user, 'User Logout', $request);
            $user->currentAccessToken()->delete();
            Log::info('Laravel Logout Successful', ['user_id' => $user->id]);
        }
        return response()->json(['success' => true, 'message' => 'Logged out']);
    }
}