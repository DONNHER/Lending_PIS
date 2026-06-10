<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\ActivityLog;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class UserController extends Controller
{
    public function index(Request $request)
    {
        $searchable = ['username', 'email', 'firstname', 'lastname', 'role', 'status'];
        $query = User::query();
        
        if ($request->boolean('trashed_only')) {
            $query->onlyTrashed();
        } elseif ($request->boolean('with_trashed')) {
            $query->withTrashed();
        }

        // Fix: Call scope correctly on the query builder instance
        $query->applyControls($request, $searchable);

        return response()->json(User::getPaginatedResponse($query, $request));
    }

    public function count(Request $request)
    {
        $query = User::query();
        if ($request->filled('role')) {
            $query->where('role', $request->role);
        }
        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }
        return response()->json([
            'success' => true,
            'count' => $query->count()
        ]);
    }

    public function show($id)
    {
        $user = User::withTrashed()->findOrFail($id);
        $auditTrail = ActivityLog::where('user_id', $id)
            ->latest('created_at')
            ->limit(20)
            ->get();

        return response()->json([
            'success' => true, 
            'data' => $user,
            'audit_trail' => $auditTrail
        ]);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'username' => 'required|string|unique:users',
            'email' => 'required|string|email|unique:users',
            'password' => 'required|string|min:8',
            'firstname' => 'required|string',
            'lastname' => 'required|string',
            'role' => 'required|string',
            'status' => 'required|string|in:active,inactive,suspended',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'errors' => $validator->errors()], 422);
        }

        $user = User::create([
            'username' => $request->username,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'firstname' => $request->firstname,
            'lastname' => $request->lastname,
            'role' => $request->role,
            'status' => $request->status,
            'mfa_enabled' => $request->boolean('mfa_enabled', true),
        ]);

        return response()->json(['success' => true, 'data' => $user], 201);
    }

    public function update(Request $request, $id)
    {
        $user = User::findOrFail($id);
        $validator = Validator::make($request->all(), [
            'username' => 'string|unique:users,username,' . $id,
            'email' => 'string|email|unique:users,email,' . $id,
            'password' => 'nullable|string|min:8',
            'firstname' => 'string',
            'lastname' => 'string',
            'role' => 'string',
            'status' => 'string|in:active,inactive,suspended',
            'version' => 'required|integer',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'errors' => $validator->errors()], 422);
        }

        try {
            $data = $request->except(['password', 'version']);
            $user->version = $request->version;
            if ($request->filled('password')) {
                $data['password'] = Hash::make($request->password);
            }
            $user->update($data);
            return response()->json(['success' => true, 'data' => $user]);
        } catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 409);
        }
    }

    public function destroy($id)
    {
        $user = User::findOrFail($id);
        if (auth()->id() === $user->id) {
            return response()->json(['success' => false, 'message' => 'Cannot delete your own account'], 403);
        }
        $user->delete();
        return response()->json(['success' => true, 'message' => 'User soft-deleted successfully']);
    }
}
