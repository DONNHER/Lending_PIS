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

    public function __construct()
    {
        // Email sending is now handled by Supabase Auth on the frontend
    }

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
                'status' => 'pending', // Keeps user pending until OTP verified
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

        if ($user->isLocked()) {
            $minutesLeft = now()->diffInMinutes($user->locked_until) + 1;
            return response()->json(['success' => false, 'message' => "Account locked. Try again in $minutesLeft mins."], 423);
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

        // If status is pending or anything else, require MFA/OTP
        return response()->json([
            'success' => true,
            'user' => $user, // Return user to check status on frontend
            'mfa_required' => true,
            'email' => $user->email,
            'message' => 'Verification required.'
        ]);
    }

    public function verifyMfa(Request $request)
    {
        $request->validate(['email' => 'required|email']);
        $user = User::where('email', $request->email)->first();

        if (!$user) {
            return response()->json(['success' => false, 'message' => 'User not found.'], 404);
        }

        // We trust the frontend if it reaches here after a Supabase OTP verification
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
