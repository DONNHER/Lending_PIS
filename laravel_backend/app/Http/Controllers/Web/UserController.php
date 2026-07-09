<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\ActivityLog;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class UserController extends Controller
{
    public function index(Request $request)
    {
        $query = User::query();

        if ($request->has('trashed')) {
            $query->onlyTrashed();
        }

        // Apply advanced controls from trait
        $query->applyControls($request, ['firstname', 'lastname', 'email', 'username']);

        $perPage = $request->get('per_page', 15);
        $users = $query->withCount(['shareholder'])->paginate($perPage)->withQueryString();

        if ($request->has('export')) {
            return $this->export($users->getCollection());
        }

        return view('admin.users.index', compact('users'));
    }

    protected function export($users)
    {
        $headers = [
            "Content-type"        => "text/csv",
            "Content-Disposition" => "attachment; filename=users_export_" . date('Y-m-d') . ".csv",
            "Pragma"              => "no-cache",
            "Cache-Control"       => "must-revalidate, post-check=0, pre-check=0",
            "Expires"             => "0"
        ];

        $callback = function() use($users) {
            $file = fopen('php://output', 'w');
            fputcsv($file, ['ID', 'Username', 'Email', 'First Name', 'Last Name', 'Role', 'Status', 'Created At']);

            foreach ($users as $u) {
                fputcsv($file, [$u->id, $u->username, $u->email, $u->firstname, $u->lastname, $u->role, $u->status, $u->created_at]);
            }
            fclose($file);
        };

        return response()->stream($callback, 200, $headers);
    }

    public function impersonate(User $user)
    {
        if (!auth()->user()->isAdmin()) abort(403);
        if ($user->id === auth()->id()) return back()->with('error', 'You cannot impersonate yourself.');

        session(['impersonator_id' => auth()->id()]);
        Auth::login($user);

        return redirect()->route('dashboard')->with('success', "Now impersonating {$user->full_name}.");
    }

    public function stopImpersonating()
    {
        $impersonatorId = session('impersonator_id');
        if (!$impersonatorId) return redirect()->route('dashboard');

        $admin = User::find($impersonatorId);
        Auth::login($admin);
        session()->forget('impersonator_id');

        return redirect()->route('admin.users.index')->with('success', 'Returned to administrator account.');
    }

    public function forceLogout(User $user)
    {
        // Revoke all tokens
        $user->tokens()->delete();

        // Note: For sessions, usually you'd need a custom driver or database sessions
        // In a simple setup, we'll log it for the next middleware check
        ActivityLog::create([
            'user_id' => $user->id,
            'action' => 'Force Logout',
            'log_type' => 'auth',
            'description' => 'Administrator forced logout from all devices.'
        ]);

        return back()->with('success', "{$user->firstname} has been forced logged out from all sessions.");
    }

    public function history(User $user)
    {
        $history = ActivityLog::where('user_id', $user->id)
            ->whereIn('log_type', ['auth', 'access'])
            ->latest()
            ->paginate(20);

        // Simple Analytics
        $topActions = ActivityLog::where('user_id', $user->id)
            ->select('action', DB::raw('count(*) as count'))
            ->groupBy('action')
            ->orderBy('count', 'desc')
            ->take(5)
            ->get();

        return view('admin.users.history', compact('user', 'history', 'topActions'));
    }

    public function bulkAction(Request $request)
    {
        $ids = $request->input('ids', []);
        $action = $request->input('action');

        if (empty($ids)) return back()->with('error', 'No users selected.');

        // Prevent self-deletion in bulk
        if ($action === 'delete' && in_array(auth()->id(), $ids)) {
            return back()->with('error', 'Bulk deletion failed: Your own account is in the selection.');
        }

        switch ($action) {
            case 'delete':
                User::whereIn('id', $ids)->delete();
                $msg = count($ids) . ' users soft-deleted.';
                break;
            case 'activate':
                User::whereIn('id', $ids)->update(['status' => 'active']);
                $msg = count($ids) . ' users set to active.';
                break;
            case 'deactivate':
                User::whereIn('id', $ids)->update(['status' => 'inactive']);
                $msg = count($ids) . ' users set to inactive.';
                break;
            case 'force-logout':
                foreach ($ids as $id) {
                    $u = User::find($id);
                    if ($u) $u->tokens()->delete();
                }
                $msg = count($ids) . ' users forced to logout.';
                break;
            default:
                return back()->with('error', 'Invalid action.');
        }

        return back()->with('success', $msg);
    }

    public function import(Request $request)
    {
        $request->validate(['file' => 'required|mimes:csv,txt']);

        $file = $request->file('file');
        $handle = fopen($file->getRealPath(), 'r');
        fgetcsv($handle); // Skip header

        $successCount = 0;
        $errors = [];
        $rowNum = 1;

        while (($row = fgetcsv($handle)) !== false) {
            $rowNum++;
            if (count($row) < 5) continue;

            $email = $row[1];
            if (User::where('email', $email)->exists()) {
                $errors[] = "Row $rowNum: User with email $email already exists.";
                continue;
            }

            try {
                User::create([
                    'firstname' => $row[2],
                    'lastname' => $row[3],
                    'email' => $email,
                    'username' => $row[0] ?: strstr($email, '@', true) . rand(100, 999),
                    'password' => \Illuminate\Support\Facades\Hash::make('Temporary123!'),
                    'role' => $row[4] ?? 'member',
                    'status' => 'active'
                ]);
                $successCount++;
            } catch (\Exception $e) {
                $errors[] = "Row $rowNum: " . $e->getMessage();
            }
        }
        fclose($handle);

        $msg = "Import finished. Success: $successCount, Errors: " . count($errors);
        if (count($errors) > 0) {
            return back()->with('error', $msg)->with('import_errors', $errors);
        }
        return back()->with('success', $msg);
    }

    public function destroy(Request $request, User user)
    {
        if ($user->id === auth()->id()) {
            return back()->with('error', 'You cannot delete your own account.');
        }

        $request->validate([
            'confirm_password' => 'required|current_password'
        ], [
            'confirm_password.current_password' => 'The password provided is incorrect. Deletion aborted.'
        ]);

        $user->delete();
        return redirect()->route('admin.users.index')->with('success', 'User has been soft-deleted.');
    }

    public function restore($id)
    {
        $user = User::withTrashed()->findOrFail($id);
        $user->restore();
        return back()->with('success', 'User account has been restored.');
    }

    public function update(Request $request, User $user)
    {
        $request->validate([
            'firstname' => 'required|string|max:255',
            'lastname' => 'required|string|max:255',
            'role' => 'required|in:admin,staff,member',
            'status' => 'required|in:active,inactive,suspended',
            'version' => 'required|integer'
        ]);

        try {
            $user->update([
                'firstname' => $request->firstname,
                'lastname' => $request->lastname,
                'role' => $request->role,
                'status' => $request->status,
                'version' => $request->version
            ]);

            return back()->with('success', "Account for {$user->email} has been updated.");
        } catch (\Exception $e) {
            return back()->with('error', $e->getMessage());
        }
    }

    public function updateStatus(Request $request, User $user)
    {
        $request->validate(['status' => 'required|in:active,inactive,suspended']);
        $user->update(['status' => $request->status]);
        return back()->with('success', 'User status updated successfully.');
    }
}
