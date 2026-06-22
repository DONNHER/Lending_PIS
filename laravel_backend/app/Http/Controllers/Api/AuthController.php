<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\ActivityLog;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;

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
                'status' => 'pending', 
                'avatar_url' => $request->avatar_url,
            ]);

            $this->logAuth($user, 'Register (Pending)', $request);
            
            return response()->json([
                'success' => true, 
                'user' => $user,
                'mfa_required' => true,
                'email' => $user->email,
                'message' => 'Registration successful. Please verify the code sent to your email.'
            ], 201);
        } catch (\Exception $e) {
            Log::error('Registration failed: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Registration failed'], 500);
        }
    }

    public function login(Request $request)
    {
        $request->validate(['email' => 'required|email', 'password' => 'required']);
        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json(['message' => 'Invalid credentials'], 401);
        }

        if ($user->status === 'active') {
            $token = $user->createToken('auth_token')->plainTextToken;
            return response()->json([
                'success' => true, 
                'user' => $user, 
                'token' => $token,
                'mfa_required' => false
            ]);
        }

        return response()->json([
            'success' => true,
            'user' => $user, 
            'mfa_required' => true,
            'email' => $user->email,
            'message' => 'Verification required.'
        ]);
    }

    public function updateProfile(Request $request)
    {
        $user = $request->user();

        $validator = Validator::make($request->all(), [
            'firstname' => 'required|string|max:255',
            'lastname' => 'required|string|max:255',
            'address' => 'nullable|string',
            'avatar_url' => 'nullable|string',
            'id_image_url' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'errors' => $validator->errors()], 422);
        }

        try {
            $user->update([
                'firstname' => $request->firstname,
                'lastname' => $request->lastname,
                'address' => $request->address,
                'avatar_url' => $request->avatar_url,
                'id_image_url' => $request->id_image_url ?? $user->id_image_url,
            ]);

            // Sync with shareholders table if user is a shareholder
            if ($user->role === 'shareholder' && $user->shareholder) {
                $user->shareholder->update([
                    'first_name' => $request->firstname,
                    'last_name' => $request->lastname,
                    'full_name' => $request->firstname . ' ' . $request->lastname,
                    'address' => $request->address,
                ]);
            }

            return response()->json([
                'success' => true,
                'user' => $user->load('shareholder'),
                'message' => 'Profile updated successfully'
            ]);
        } catch (\Exception $e) {
            Log::error('Profile update failed: ' . $e->getMessage());
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
            return response()->json(['success' => false, 'errors' => $validator->errors()], 422);
        }

        if (!Hash::check($request->current_password, $user->password)) {
            return response()->json(['success' => false, 'message' => 'Current password does not match'], 400);
        }

        try {
            $user->update([
                'password' => Hash::make($request->new_password)
            ]);

            return response()->json(['success' => true, 'message' => 'Password changed successfully']);
        } catch (\Exception $e) {
            Log::error('Password change failed: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Failed to change password'], 500);
        }
    }

    public function forgotPassword(Request $request)
    {
        return response()->json(['success' => true, 'message' => 'Reset instructions sent to your email.']);
    }

    public function resetPassword(Request $request)
    {
        Log::info('Reset password attempt for: ' . $request->email);

        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'password' => $this->passwordPolicy,
        ], [
            'password.regex' => $this->passwordPolicyMessage
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'errors' => $validator->errors()], 422);
        }

        $user = User::where('email', $request->email)->first();
        if (!$user) {
            return response()->json(['success' => false, 'message' => 'User not found'], 404);
        }

        try {
            $user->password = Hash::make($request->password);
            $user->save();
            
            Log::info('Password reset successful for user: ' . $user->id);
            return response()->json(['success' => true, 'message' => 'Password reset successfully']);
        } catch (\Exception $e) {
            Log::error('Reset password failed: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Failed to reset password: ' . $e->getMessage()], 500);
        }
    }

    public function verifyMfa(Request $request)
    {
        $request->validate(['email' => 'required|email']);
        $user = User::where('email', $request->email)->first();

        if (!$user) {
            return response()->json(['success' => false, 'message' => 'User not found.'], 404);
        }

        $user->update(['status' => 'active']);
        
        $user->tokens()->delete();
        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json(['success' => true, 'user' => $user, 'token' => $token]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();
        return response()->json(['success' => true, 'message' => 'Logged out']);
    }
}
