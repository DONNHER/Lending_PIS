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
use App\Imports\UsersImport;
use App\Imports\ActivityLogsImport; // Added this import

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
        $type = strtolower(trim($type ?? $request->route('type')));
        $format = strtolower(trim($format ?? $request->route('format')));
        $filename = $type . '_report_' . now()->format('Ymd_His');

        if (in_array($format, ['xlsx', 'csv'])) {
            return match($type) {
                'transactions'  => Excel::download(new TransactionsExport(), $filename . '.' . $format),
                'users'         => Excel::download(new UsersExport(), $filename . '.' . $format),
                'loans'         => Excel::download(new LoansExport(), $filename . '.' . $format),
                'activity-logs' => Excel::download(new ActivityLogsExport(), $filename . '.' . $format), // Updated key
                default         => response()->json(['error' => 'Format/Type not supported'], 400),
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

        $import = $this->getImportInstance($type);

        if (!$import) return response()->json(['message' => 'Type not supported'], 404);

        try {
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

        $import = $this->getImportInstance($type);

        if (!$import) return response()->json(['message' => 'Type not supported'], 404);

        try {
            $import->isPreview = false;
            Excel::import($import, $request->file('file'));
            return response()->json(['message' => 'Import completed successfully']);
        } catch (\Exception $e) {
            Log::error("Import Confirmation Error [{$type}]: " . $e->getMessage());
            return response()->json(['message' => 'Import failed: ' . $e->getMessage()], 500);
        }
    }

    /**
     * Helper to resolve Import classes
     */
    private function getImportInstance($type)
    {
        return match($type) {
            'loans'         => new LoansImport(),
            'transactions'  => new TransactionsImport(),
            'users'         => new UsersImport(),
            'activity-logs' => new ActivityLogsImport(), // Added mapping
            default         => null,
        };
    }

    private function generatePdfReport($type, $filename) { /* ... keep existing implementation ... */ }
}