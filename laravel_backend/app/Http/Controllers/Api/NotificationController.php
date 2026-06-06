<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Notification;
use Illuminate\Http\Request;

/**
 * Class NotificationController
 * 
 * Handles system and user notifications. 
 * Supports advanced data controls, bulk actions, and CSV exporting.
 * 
 * @package App\Http\Controllers\Api
 */
class NotificationController extends Controller
{
    /**
     * Display a listing of notifications with advanced controls.
     * Filterable by shareholder, unread status, and standard search terms.
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function index(Request $request)
    {
        $searchable = ['title', 'content', 'category', 'type'];
        
        $query = Notification::applyControls($request, $searchable);

        // Filter by shareholder or comaker participation
        if ($request->filled('shareholder_id')) {
            $query->where(function($q) use ($request) {
                $q->where('shareholder_id', $request->shareholder_id)
                  ->orWhere('comaker_id', $request->shareholder_id);
            });
        }

        // Filter by read/unread status
        if ($request->filled('is_unread')) {
            $query->where('is_unread', $request->boolean('is_unread'));
        }

        return response()->json(Notification::getPaginatedResponse($query, $request));
    }

    /**
     * Mark a single notification as read.
     */
    public function markAsRead($id)
    {
        $notification = Notification::findOrFail($id);
        $notification->update(['is_unread' => false]);

        return response()->json(['success' => true]);
    }

    /**
     * Mark all notifications for a specific shareholder as read.
     */
    public function markAllAsRead(Request $request)
    {
        $request->validate(['shareholder_id' => 'required|uuid']);

        Notification::where('shareholder_id', $request->shareholder_id)
            ->orWhere('comaker_id', $request->shareholder_id)
            ->update(['is_unread' => false]);

        return response()->json(['success' => true]);
    }

    /**
     * Perform bulk operations (delete, mark_read, export) on notifications.
     */
    public function bulkAction(Request $request)
    {
        $request->validate([
            'ids' => 'required|array',
            'action' => 'required|string|in:delete,mark_read,export',
        ]);

        $ids = $request->ids;

        switch ($request->action) {
            case 'delete':
                Notification::whereIn('id', $ids)->delete();
                return response()->json(['success' => true, 'message' => count($ids) . ' notifications deleted.']);
            
            case 'mark_read':
                Notification::whereIn('id', $ids)->update(['is_unread' => false]);
                return response()->json(['success' => true, 'message' => count($ids) . ' notifications marked as read.']);
            
            case 'export':
                return $this->export($request, $ids);
        }
    }

    /**
     * Export selected notifications to a CSV file.
     */
    public function export(Request $request, $ids = null)
    {
        $query = Notification::query();
        if ($ids) {
            $query->whereIn('id', $ids);
        } else {
            $query = Notification::applyControls($request, ['title', 'category']);
        }

        $data = $query->get();
        $filename = 'notifications_export_' . date('Ymd_His') . '.csv';
        
        $headers = [
            "Content-type"        => "text/csv",
            "Content-Disposition" => "attachment; filename=$filename",
            "Pragma"              => "no-cache",
            "Cache-Control"       => "must-revalidate, post-check=0, pre-check=0",
            "Expires"             => "0"
        ];

        $columns = ['ID', 'Title', 'Category', 'Type', 'Status', 'Created At'];

        $callback = function() use($data, $columns) {
            $file = fopen('php://output', 'w');
            fputcsv($file, $columns);
            foreach ($data as $row) {
                fputcsv($file, [
                    $row->id,
                    $row->title,
                    $row->category,
                    $row->type,
                    $row->is_unread ? 'Unread' : 'Read',
                    $row->created_at
                ]);
            }
            fclose($file);
        };

        return response()->stream($callback, 200, $headers);
    }
}
