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

/**
 * Class UserController
 * 
 * Manages administrative user operations including CRUD, impersonation,
 * analytics, and bulk data processing. Restricted to 'admin' role.
 * 
 * @package App\Http\Controllers\Api
 */
class UserController extends Controller
{
    /**
     * Display a listing of users with advanced controls.
     * Supports pagination, global search, and filtering by role/status.
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function index(Request $request)
    {
        $searchable = ['username', 'email', 'firstname', 'lastname', 'role', 'status'];
        
        $query = User::query();
        
        // Handle Soft Delete filters
        if ($request->boolean('trashed_only')) {
            $query->onlyTrashed();
        } elseif ($request->boolean('with_trashed')) {
            $query->withTrashed();
        }

        $query = User::applyControls($query, $request, $searchable);

        return response()->json(User::getPaginatedResponse($query, $request));
    }

    /**
     * Display a specific user with its audit trail.
     * 
     * @param string $id User UUID
     * @return \Illuminate\Http\JsonResponse
     */
    public function show($id)
    {
        $user = User::withTrashed()->findOrFail($id);
        
        // Fetch specific audit trail for this user
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

    /**
     * Create a new user account.
     */
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

        return response()->json([
            'success' => true, 
            'message' => 'User created successfully', 
            'data' => $user
        ], 201);
    }

    /**
     * Update a user account with Optimistic Locking.
     */
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
            'version' => 'required|integer', // Required for optimistic locking
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'errors' => $validator->errors()], 422);
        }

        try {
            $data = $request->except(['password', 'version']);
            $user->version = $request->version; // Set for Versionable trait
            
            if ($request->filled('password')) {
                $data['password'] = Hash::make($request->password);
            }

            $user->update($data);

            return response()->json([
                'success' => true, 
                'message' => 'User updated successfully', 
                'data' => $user
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false, 
                'message' => $e->getMessage()
            ], 409); // Conflict detected
        }
    }

    /**
     * Soft delete a user account.
     * Prevents self-deletion and checks for financial dependencies.
     */
    public function destroy($id)
    {
        $user = User::findOrFail($id);
        
        if (auth()->id() === $user->id) {
            return response()->json(['success' => false, 'message' => 'Cannot delete your own account'], 403);
        }

        // Cascade delete warning logic
        $hasLoans = $user->shareholder && $user->shareholder->loans()->exists();
        if ($hasLoans && !request()->boolean('force')) {
            return response()->json([
                'success' => false,
                'requires_confirmation' => true,
                'message' => 'This user has active loans. Deleting will affect financial records. Proceed?'
            ], 409);
        }

        $user->delete();
        return response()->json(['success' => true, 'message' => 'User soft-deleted successfully']);
    }

    /**
     * Restore a soft-deleted user.
     */
    public function restore($id)
    {
        $user = User::onlyTrashed()->findOrFail($id);
        $user->restore();

        return response()->json(['success' => true, 'message' => 'User restored successfully', 'data' => $user]);
    }

    /**
     * Impersonate a user for support purposes.
     * Generates a 1-hour session token for the target user.
     */
    public function impersonate($id)
    {
        $user = User::findOrFail($id);
        $token = $user->createToken('impersonation_token', ['*'], now()->addHours(1))->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Impersonation token generated',
            'token' => $token,
            'user' => $user
        ]);
    }

    /**
     * Terminate all active sessions for a user.
     */
    public function forceLogout($id)
    {
        $user = User::findOrFail($id);
        $user->tokens()->delete();

        return response()->json(['success' => true, 'message' => 'User logged out from all devices']);
    }

    /**
     * Fetch authentication history and device info for a user.
     */
    public function loginHistory($id)
    {
        $history = ActivityLog::where('user_id', $id)
            ->where('log_type', ActivityLog::TYPE_AUTH)
            ->latest('created_at')
            ->limit(50)
            ->get();

        return response()->json(['success' => true, 'data' => $history]);
    }

    /**
     * Detailed user activity analytics.
     */
    public function analytics($id)
    {
        $user = User::findOrFail($id);
        $lastActive = ActivityLog::where('user_id', $id)->latest('created_at')->first();
        $mostUsedFeatures = ActivityLog::where('user_id', $id)
            ->where('log_type', ActivityLog::TYPE_ACCESS)
            ->select('action', DB::raw('count(*) as count'))
            ->groupBy('action')
            ->orderBy('count', 'desc')
            ->limit(5)
            ->get();

        return response()->json([
            'success' => true,
            'data' => [
                'last_active' => $lastActive ? $lastActive->created_at : null,
                'most_used_features' => $mostUsedFeatures,
                'total_actions' => ActivityLog::where('user_id', $id)->count(),
                'total_errors' => ActivityLog::where('user_id', $id)->where('log_type', ActivityLog::TYPE_ERROR)->count(),
            ]
        ]);
    }

    /**
     * Perform bulk operations on users.
     */
    public function bulkAction(Request $request)
    {
        $request->validate([
            'ids' => 'required|array',
            'action' => 'required|string|in:delete,restore,update_status,export',
            'status' => 'required_if:action,update_status'
        ]);

        $ids = $request->ids;

        switch ($request->action) {
            case 'delete':
                User::whereIn('id', $ids)->where('id', '!=', auth()->id())->delete();
                return response()->json(['success' => true, 'message' => 'Selected users soft-deleted.']);
            
            case 'restore':
                User::onlyTrashed()->whereIn('id', $ids)->restore();
                return response()->json(['success' => true, 'message' => 'Selected users restored.']);

            case 'update_status':
                User::whereIn('id', $ids)->update(['status' => $request->status]);
                return response()->json(['success' => true, 'message' => 'Status updated for selected users.']);
            
            case 'export':
                return $this->export($request, $ids);
        }
    }

    /**
     * Bulk import users from a CSV file.
     */
    public function import(Request $request)
    {
        $request->validate(['file' => 'required|file|mimes:csv,txt']);

        $path = $request->file('file')->getRealPath();
        $data = array_map('str_getcsv', file($path));
        $header = array_shift($data);

        $count = 0;
        foreach ($data as $row) {
            $userRow = array_combine($header, $row);
            if (User::where('email', $userRow['Email'])->exists() || User::where('username', $userRow['Username'])->exists()) {
                continue;
            }

            User::create([
                'username' => $userRow['Username'],
                'email' => $userRow['Email'],
                'password' => Hash::make($userRow['Password'] ?? Str::random(12)),
                'firstname' => $userRow['Firstname'],
                'lastname' => $userRow['Lastname'],
                'role' => $userRow['Role'] ?? 'member',
                'status' => 'active',
                'mfa_enabled' => true,
            ]);
            $count++;
        }

        return response()->json(['success' => true, 'message' => "$count users imported successfully."]);
    }

    /**
     * Export users to a downloadable CSV file.
     */
    public function export(Request $request, $ids = null)
    {
        $query = User::query();
        if ($ids) {
            $query->whereIn('id', $ids);
        } else {
            $query = User::applyControls($query, $request, ['username', 'email', 'firstname', 'lastname']);
        }

        $users = $query->get();
        $filename = 'users_export_' . date('Ymd_His') . '.csv';
        
        $headers = [
            "Content-type"        => "text/csv",
            "Content-Disposition" => "attachment; filename=$filename",
        ];

        $callback = function() use($users) {
            $file = fopen('php://output', 'w');
            fputcsv($file, ['ID', 'Username', 'Email', 'Firstname', 'Lastname', 'Role', 'Status', 'MFA Enabled', 'Created At']);

            foreach ($users as $user) {
                fputcsv($file, [
                    $user->id,
                    $user->username,
                    $user->email,
                    $user->firstname,
                    $user->lastname,
                    $user->role,
                    $user->status,
                    $user->mfa_enabled ? 'Yes' : 'No',
                    $user->created_at,
                ]);
            }
            fclose($file);
        };

        return response()->stream($callback, 200, $headers);
    }
}
