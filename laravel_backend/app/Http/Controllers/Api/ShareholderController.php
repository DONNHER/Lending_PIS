<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Shareholder;
use App\Models\User;
use App\Models\ActivityLog;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class ShareholderController extends Controller
{
    /**
     * Display a listing of shareholders.
     * Eager loads 'user' to provide account status and role.
     */
    public function index(Request $request)
    {
        $searchable = ['first_name', 'last_name', 'email', 'status'];
        
        // 🚀 Fix: Eager load 'user' so we can access account status in the frontend
        $query = Shareholder::with(['user']);

        if ($request->boolean('trashed_only')) {
            $query->onlyTrashed();
        } elseif ($request->boolean('with_trashed')) {
            $query->withTrashed();
        }

        $query->applyControls($request, $searchable);

        return response()->json(Shareholder::getPaginatedResponse($query, $request));
    }

    /**
     * Display a specific shareholder.
     * Handles both Shareholder ID and User ID fallback.
     */
    public function show($id)
    {
        $shareholder = Shareholder::withTrashed()->with(['user'])->find($id);
        
        if (!$shareholder) {
            $shareholder = Shareholder::withTrashed()->with(['user'])->where('user_id', $id)->first();
        }

        if (!$shareholder) {
            $user = User::find($id);
            if ($user) {
                return response()->json([
                    'success' => true,
                    'data' => [
                        'id' => '', 
                        'user_id' => $user->id,
                        'first_name' => $user->firstname,
                        'last_name' => $user->lastname,
                        'full_name' => "$user->firstname $user->lastname",
                        'email' => $user->email,
                        'contact_number' => '',
                        'address' => '',
                        'status' => $user->status,
                        'total_share_capital' => 0,
                        'creditscore' => 0,
                        'role' => $user->role,
                        'user' => $user
                    ]
                ]);
            }
            return response()->json(['success' => false, 'message' => 'Record not found'], 404);
        }

        $auditTrail = ActivityLog::where('description', 'like', "%shareholders (ID: {$id})%")
            ->latest('created_at')
            ->limit(20)
            ->get();

        return response()->json([
            'success' => true, 
            'data' => $shareholder,
            'audit_trail' => $auditTrail
        ]);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email|unique:shareholders',
            'first_name' => 'required|string',
            'last_name' => 'required|string',
            'user_id' => 'nullable|exists:users,id',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'errors' => $validator->errors()], 422);
        }

        try {
            $shareholder = Shareholder::create($request->all());
            return response()->json([
                'success' => true, 
                'message' => 'Shareholder record created successfully',
                'data' => $shareholder
            ], 201);
        } catch (\Exception $e) {
            Log::error('Shareholder creation failed: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }
    }

    public function update(Request $request, $id)
    {
        $shareholder = Shareholder::findOrFail($id);

        try {
            $shareholder->update($request->all());
            return response()->json([
                'success' => true, 
                'message' => 'Shareholder updated successfully', 
                'data' => $shareholder
            ]);
        } catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 409);
        }
    }

    public function destroy($id)
    {
        $shareholder = Shareholder::find($id);
        if (!$shareholder) return response()->json(['success' => false, 'message' => 'Not found'], 404);

        $hasActiveLoans = $shareholder->loans()->where('status', 'Active')->exists();
        if ($hasActiveLoans && !request()->boolean('force')) {
            return response()->json([
                'success' => false,
                'requires_confirmation' => true,
                'message' => 'This shareholder has active loans. Deleting will complicate repayment tracking. Proceed?'
            ], 409);
        }

        if ($shareholder->user_id && request()->boolean('delete_user')) {
            User::where('id', $shareholder->user_id)->delete();
        }

        $shareholder->delete();
        return response()->json(['success' => true, 'message' => 'Shareholder soft-deleted successfully']);
    }

    public function showByUserId($userId)
    {
        $shareholder = Shareholder::with('user')->where('user_id', $userId)->first();
        if (!$shareholder) return $this->show($userId);
        return response()->json(['success' => true, 'data' => $shareholder]);
    }

    public function showByEmail($email)
    {
        $shareholder = Shareholder::with('user')->where('email', $email)->first();
        if (!$shareholder) {
            return response()->json(['success' => false, 'message' => 'Shareholder not found'], 404);
        }
        return response()->json(['success' => true, 'data' => $shareholder]);
    }

    public function count()
    {
        return response()->json([
            'success' => true,
            'count' => Shareholder::count()
        ]);
    }

    /**
     * Update the total share capital of a shareholder.
     */
    public function updateCapital(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'total_share_capital' => 'required|numeric|min:0',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'errors' => $validator->errors()], 422);
        }

        $shareholder = Shareholder::find($id);
        
        if (!$shareholder) {
            return response()->json(['success' => false, 'message' => 'Shareholder not found'], 404);
        }

        try {
            $shareholder->update([
                'total_share_capital' => $request->total_share_capital
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Share capital updated successfully',
                'data' => $shareholder
            ]);
        } catch (\Exception $e) {
            Log::error('Share capital update failed: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }
    }
}
