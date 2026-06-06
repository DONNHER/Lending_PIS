<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Shareholder;
use App\Models\User;
use App\Models\ActivityLog;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

/**
 * Class ShareholderController
 * 
 * Manages records for shareholders, including their share capital, 
 * membership status, and associated user accounts.
 * 
 * @package App\Http\Controllers\Api
 */
class ShareholderController extends Controller
{
    /**
     * Display a listing of shareholders with advanced controls.
     * Supports pagination, global search, and filtering by status.
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function index(Request $request)
    {
        $searchable = ['firstname', 'lastname', 'email', 'status'];
        
        $query = Shareholder::query();

        // Handle Soft Delete filters
        if ($request->boolean('trashed_only')) {
            $query->onlyTrashed();
        } elseif ($request->boolean('with_trashed')) {
            $query->withTrashed();
        }

        $query = Shareholder::applyControls($query, $request, $searchable);

        return response()->json(Shareholder::getPaginatedResponse($query, $request));
    }

    /**
     * READ: Display a specific shareholder's details and their audit trail.
     */
    public function show($id)
    {
        $shareholder = Shareholder::withTrashed()->with(['user'])->find($id);
        if (!$shareholder) {
            return response()->json(['success' => false, 'message' => 'Shareholder not found'], 404);
        }

        // Fetch audit logs specifically for this shareholder record
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

    /**
     * CREATE: Register a new shareholder.
     * Success results in an automatic entry in the audit trail.
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email|unique:shareholders',
            'firstname' => 'required|string',
            'lastname' => 'required|string',
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
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }
    }

    /**
     * UPDATE: Update shareholder information.
     * Implements Optimistic Locking using the 'version' field.
     */
    public function update(Request $request, $id)
    {
        $shareholder = Shareholder::findOrFail($id);

        $request->validate([
            'version' => 'required|integer', // Required for concurrency check
        ]);

        try {
            $shareholder->version = $request->version;
            $shareholder->update($request->all());

            return response()->json([
                'success' => true, 
                'message' => 'Shareholder updated successfully', 
                'data' => $shareholder
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false, 
                'message' => $e->getMessage()
            ], 409); // Conflict detected
        }
    }

    /**
     * DELETE: Soft-delete a shareholder record.
     * Checks for active loans before allowing deletion.
     */
    public function destroy($id)
    {
        $shareholder = Shareholder::findOrFail($id);

        // Cascade delete warning: Check for financial obligations
        $hasActiveLoans = $shareholder->loans()->where('status', 'Active')->exists();
        if ($hasActiveLoans && !request()->boolean('force')) {
            return response()->json([
                'success' => false,
                'requires_confirmation' => true,
                'message' => 'This shareholder has active loans. Deleting will complicate repayment tracking. Proceed?'
            ], 409);
        }

        // Option to also delete the linked user account
        if ($shareholder->user_id && request()->boolean('delete_user')) {
            User::where('id', $shareholder->user_id)->delete();
        }

        $shareholder->delete();
        return response()->json(['success' => true, 'message' => 'Shareholder soft-deleted successfully']);
    }

    /**
     * Restore a soft-deleted shareholder record.
     */
    public function restore($id)
    {
        $shareholder = Shareholder::onlyTrashed()->findOrFail($id);
        $shareholder->restore();

        return response()->json([
            'success' => true, 
            'message' => 'Shareholder record restored successfully', 
            'data' => $shareholder
        ]);
    }

    /**
     * Find a shareholder record by its linked user ID.
     */
    public function showByUserId($userId)
    {
        $shareholder = Shareholder::with('user')->where('user_id', $userId)->first();
        return response()->json(['success' => true, 'data' => $shareholder]);
    }

    /**
     * Find a shareholder record by email.
     */
    public function showByEmail($email)
    {
        $shareholder = Shareholder::with('user')->where('email', $email)->first();
        if (!$shareholder) {
            return response()->json(['success' => false, 'message' => 'Shareholder not found'], 404);
        }
        return response()->json(['success' => true, 'data' => $shareholder]);
    }

    /**
     * Perform bulk operations (delete, restore, status update, export) on multiple records.
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
                Shareholder::whereIn('id', $ids)->delete();
                return response()->json(['success' => true, 'message' => count($ids) . ' records soft-deleted.']);
            
            case 'restore':
                Shareholder::onlyTrashed()->whereIn('id', $ids)->restore();
                return response()->json(['success' => true, 'message' => count($ids) . ' records restored.']);

            case 'update_status':
                Shareholder::whereIn('id', $ids)->update(['status' => $request->status]);
                return response()->json(['success' => true, 'message' => count($ids) . ' records updated.']);
            
            case 'export':
                return $this->export($request, $ids);
        }
    }

    /**
     * Export the filtered list or specific shareholders to a CSV file.
     */
    public function export(Request $request, $ids = null)
    {
        $query = Shareholder::query();
        if ($ids) {
            $query->whereIn('id', $ids);
        } else {
            $query = Shareholder::applyControls($query, $request, ['firstname', 'lastname', 'email']);
        }

        $data = $query->get();
        $filename = 'shareholders_export_' . date('Ymd_His') . '.csv';
        
        $headers = [
            "Content-type"        => "text/csv",
            "Content-Disposition" => "attachment; filename=$filename",
        ];

        $callback = function() use($data) {
            $file = fopen('php://output', 'w');
            fputcsv($file, ['ID', 'First Name', 'Last Name', 'Email', 'Share Capital', 'Status', 'Created At']);
            foreach ($data as $row) {
                fputcsv($file, [
                    $row->id, $row->firstname, $row->lastname, $row->email, $row->share_capital, $row->status, $row->created_at
                ]);
            }
            fclose($file);
        };

        return response()->stream($callback, 200, $headers);
    }

    /**
     * Get the total count of registered shareholders.
     */
    public function count()
    {
        return response()->json([
            'success' => true,
            'count' => Shareholder::count()
        ]);
    }
}
