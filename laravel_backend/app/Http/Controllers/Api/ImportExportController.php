<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Maatwebsite\Excel\Facades\Excel;
use Barryvdh\DomPDF\Facade\Pdf;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;

// Exports
use App\Exports\TransactionsExport;
use App\Exports\UsersExport;
use App\Exports\LoansExport;
use App\Exports\ActivityLogsExport;

// Imports
use App\Imports\LoansImport;
use App\Imports\TransactionsImport;

// Models
use App\Models\Transaction;
use App\Models\User;
use App\Models\Loan;

class ImportExportController extends Controller
{
    /**
     * Handle Exports (Excel/CSV/PDF)
     */
    public function export(Request $request, $type = null, $format = null)
    {
        // Fallback to route parameters if dependency injection missed them
        $type = strtolower(trim($type ?? $request->route('type')));
        $format = strtolower(trim($format ?? $request->route('format')));
        $filename = $type . '_report_' . now()->format('Ymd_His');

        if (in_array($format, ['xlsx', 'csv'])) {
            return match($type) {
                'transactions' => Excel::download(new TransactionsExport(), $filename . '.' . $format),
                'users'        => Excel::download(new UsersExport(), $filename . '.' . $format),
                'loans'        => Excel::download(new LoansExport(), $filename . '.' . $format),
                'activitylogs' => Excel::download(new ActivityLogsExport(), $filename . '.' . $format),
                default        => response()->json(['error' => 'Format/Type not supported'], 400),
            };
        }

        if ($format === 'pdf') {
            return $this->generatePdfReport($type, $filename);
        }

        return response()->json(['error' => 'Unsupported format.'], 400);
    }

    /**
     * Preview Import (Dry Run)
     */
    public function previewImport(Request $request, $type)
    {
        $request->validate(['file' => 'required|file|mimes:xlsx,csv']);

        $import = match($type) {
            'loans'        => new LoansImport(),
            'transactions' => new TransactionsImport(),
            default        => null,
        };

        if (!$import) return response()->json(['message' => 'Type not supported'], 404);

        try {
            // Set flag to skip DB creation
            $import->isPreview = true;
            Excel::import($import, $request->file('file'));

            return response()->json([
                'success' => empty($import->errors),
                'errors' => $import->errors ?? [],
                'count' => count($import->errors ?? [])
            ]);
        } catch (\Exception $e) {
            Log::error("Import Preview Error [{$type}]: " . $e->getMessage());
            return response()->json(['message' => 'Server Error: ' . $e->getMessage()], 500);
        }
    }

    /**
     * Confirm Import (Final Save)
     */
    public function confirmImport(Request $request, $type)
    {
        $request->validate(['file' => 'required|file|mimes:xlsx,csv']);

        $import = match($type) {
            'loans'        => new LoansImport(),
            'transactions' => new TransactionsImport(),
            default        => null,
        };

        try {
            $import->isPreview = false; // Allow DB writes
            Excel::import($import, $request->file('file'));
            return response()->json(['message' => 'Import completed successfully']);
        } catch (\Exception $e) {
            Log::error("Import Confirmation Error [{$type}]: " . $e->getMessage());
            return response()->json(['message' => 'Import failed: ' . $e->getMessage()], 500);
        }
    }

    /**
     * Helper for PDF Generation
     */
    private function generatePdfReport($type, $filename)
    {
        $viewName = 'reports.generic';
        $data = ['title' => ucwords(str_replace('-', ' ', $type)) . ' Report', 'generatedAt' => now()->toDateTimeString()];

        if ($type === 'transactions') {
            $data['headers'] = ['ID', 'Reference', 'Shareholder', 'Type', 'Method', 'Amount', 'Status', 'Date'];
            $data['rows'] = Transaction::with('shareholder.user')->get()->map(fn($tx) => [
                'id' => $tx->id, 'reference_id' => $tx->reference_id, 'shareholder' => $tx->shareholder?->user?->fullName ?? 'N/A',
                'type' => strtoupper($tx->type), 'method' => strtoupper($tx->method), 'amount' => number_format($tx->amount, 2),
                'status' => strtoupper($tx->status), 'date' => $tx->date
            ])->toArray();
        } elseif ($type === 'loans') {
            $data['headers'] = ['ID', 'Principal', 'Interest', 'Tenure', 'Balance', 'Status'];
            $data['rows'] = Loan::all()->map(fn($l) => [
                'id' => $l->id, 'principal' => $l->principal_amount, 'interest' => $l->interest_rate,
                'tenure' => $l->tenure_months, 'balance' => $l->remaining_balance, 'status' => $l->status
            ])->toArray();
        }

        $pdf = Pdf::loadView($viewName, $data);
        return $pdf->setPaper('a4', 'portrait')->stream($filename . '.pdf');
    }
}