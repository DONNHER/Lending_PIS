<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Shareholder;
use App\Models\Transaction;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ShareholderController extends Controller
{
    public function index(Request $request)
    {
        $query = Shareholder::query();

        if ($request->has('trashed')) {
            $query->onlyTrashed();
        }

        // Apply advanced controls from trait
        $query->applyControls($request, ['firstname', 'lastname', 'email', 'contact_number']);

        // Additional column-specific filters
        if ($request->filled('min_capital')) {
            $query->where('total_share_capital', '>=', $request->min_capital);
        }
        if ($request->filled('max_capital')) {
            $query->where('total_share_capital', '<=', $request->max_capital);
        }

        $perPage = $request->get('per_page', 10);
        $shareholders = $query->paginate($perPage)->withQueryString();

        return view('admin.shareholders.index', compact('shareholders'));
    }

    public function bulkAction(Request $request)
    {
        $ids = $request->input('ids', []);
        $action = $request->input('action');

        if (empty($ids)) return back()->with('error', 'No records selected.');

        switch ($action) {
            case 'delete':
                Shareholder::whereIn('id', $ids)->delete();
                $msg = count($ids) . ' shareholders soft-deleted.';
                break;
            case 'activate':
                Shareholder::whereIn('id', $ids)->update(['status' => 'active']);
                $msg = count($ids) . ' shareholders activated.';
                break;
            case 'deactivate':
                Shareholder::whereIn('id', $ids)->update(['status' => 'inactive']);
                $msg = count($ids) . ' shareholders deactivated.';
                break;
            default:
                return back()->with('error', 'Invalid bulk action.');
        }

        return back()->with('success', $msg);
    }

    public function destroy(Request $request, Shareholder $shareholder)
    {
        // Check for active loans before deleting
        if ($shareholder->loans()->where('status', 'active')->exists()) {
            return back()->with('error', 'Cannot delete shareholder with active loans. Please settle or close loans first.');
        }

        $request->validate([
            'confirm_password' => 'required|current_password'
        ], [
            'confirm_password.current_password' => 'Incorrect password. Cascade deletion prevented.'
        ]);

        $shareholder->delete();
        return redirect()->route('admin.shareholders.index')->with('success', 'Shareholder has been soft-deleted.');
    }

    public function restore($id)
    {
        $shareholder = Shareholder::withTrashed()->findOrFail($id);
        $shareholder->restore();
        return back()->with('success', 'Shareholder record has been restored.');
    }

    public function export(Request $request)
    {
        $format = $request->get('format', 'csv');
        $shareholders = Shareholder::all();

        if ($format === 'csv') {
            $headers = [
                "Content-type"        => "text/csv",
                "Content-Disposition" => "attachment; filename=shareholders_export_" . date('Y-m-d') . ".csv",
                "Pragma"              => "no-cache",
                "Cache-Control"       => "must-revalidate, post-check=0, pre-check=0",
                "Expires"             => "0"
            ];

            $callback = function() use($shareholders) {
                $file = fopen('php://output', 'w');
                fputcsv($file, ['First Name', 'Last Name', 'Email', 'Contact Number', 'Address', 'Total Capital', 'Status']);

                foreach ($shareholders as $s) {
                    fputcsv($file, [$s->firstname, $s->lastname, $s->email, $s->contact_number, $s->address, $s->total_share_capital, $s->status]);
                }
                fclose($file);
            };

            return response()->stream($callback, 200, $headers);
        }

        // PDF / Print View
        return view('admin.shareholders.print', compact('shareholders'));
    }

    public function import(Request $request)
    {
        $request->validate(['file' => 'required|mimes:csv,txt']);

        $file = $request->file('file');
        $handle = fopen($file->getRealPath(), 'r');
        $header = fgetcsv($handle); // Skip header

        $successCount = 0;
        $errorCount = 0;
        $errors = [];
        $rowNum = 1;

        while (($row = fgetcsv($handle)) !== false) {
            $rowNum++;
            if (count($row) < 3) continue;

            $data = [
                'firstname' => $row[0],
                'lastname' => $row[1],
                'email' => $row[2],
                'contact_number' => $row[3] ?? null,
                'address' => $row[4] ?? null,
                'status' => 'active'
            ];

            // Simple validation & Duplicate check
            if (empty($data['email']) || !filter_var($data['email'], FILTER_VALIDATE_EMAIL)) {
                $errors[] = "Row $rowNum: Invalid email format.";
                $errorCount++;
                continue;
            }

            if (Shareholder::where('email', $data['email'])->exists()) {
                $errors[] = "Row $rowNum: Duplicate entry for email {$data['email']}.";
                $errorCount++;
                continue;
            }

            try {
                Shareholder::create($data);
                $successCount++;
            } catch (\Exception $e) {
                $errors[] = "Row $rowNum: " . $e->getMessage();
                $errorCount++;
            }
        }
        fclose($handle);

        $msg = "Import finished. Success: $successCount, Failed: $errorCount.";
        if ($errorCount > 0) {
            return back()->with('error', $msg)->with('import_errors', $errors);
        }
        return back()->with('success', $msg);
    }

    public function create()
    {
        return view('admin.shareholders.create');
    }

    public function show(Shareholder $shareholder)
    {
        $shareholder->load(['loans', 'transactions']);
        return view('admin.shareholders.show', compact('shareholder'));
    }

    public function addCapital(Shareholder $shareholder)
    {
        return view('admin.shareholders.add-capital', compact('shareholder'));
    }

    public function update(Request $request, Shareholder $shareholder)
    {
        $request->validate([
            'firstname' => 'required|string|max:255',
            'lastname' => 'required|string|max:255',
            'email' => 'required|email|unique:shareholders,email,' . $shareholder->id,
            'contact_number' => ['nullable', 'string', 'regex:/^(09|\+639)\d{9}$/'],
            'address' => 'nullable|string|max:500',
            'version' => 'required|integer'
        ], [
            'contact_number.regex' => 'The phone number must be a valid Philippine mobile number (e.g., 09123456789).',
        ]);

        try {
            $shareholder->update([
                'first_name' => $request->firstname,
                'last_name' => $request->lastname,
                'full_name' => $request->firstname . ' ' . $request->lastname,
                'email' => $request->email,
                'contact_number' => $request->contact_number,
                'address' => $request->address,
                'version' => $request->version
            ]);

            return back()->with('success', 'Shareholder details updated.');
        } catch (\Exception $e) {
            return back()->with('error', $e->getMessage());
        }
    }
