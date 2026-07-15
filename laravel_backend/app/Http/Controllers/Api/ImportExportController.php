<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Maatwebsite\Excel\Facades\Excel;
use App\Exports\UsersExport;
use App\Imports\UsersImport;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Exception;

class ImportExportController extends Controller
{
    /**
     * Export data in various formats.
     */
    public function export($type, $format)
    {
        $export = null;
        $fileName = $type . '_' . date('Ymd_His');

        switch ($type) {
            case 'users':
                $export = new UsersExport();
                break;
            case 'loans':
                $export = new \App\Exports\LoansExport();
                break;
            case 'transactions':
                $export = new \App\Exports\TransactionsExport();
                break;
            case 'activity-logs':
                $export = new \App\Exports\ActivityLogsExport();
                break;
            default:
                return response()->json(['success' => false, 'message' => 'Invalid export type'], 400);
        }

        $extension = '';
        $writerType = '';

        switch (strtolower($format)) {
            case 'xlsx':
                $extension = '.xlsx';
                $writerType = \Maatwebsite\Excel\Excel::XLSX;
                break;
            case 'csv':
                $extension = '.csv';
                $writerType = \Maatwebsite\Excel\Excel::CSV;
                break;
            case 'pdf':
                $extension = '.pdf';
                $writerType = \Maatwebsite\Excel\Excel::DOMPDF;
                break;
            default:
                return response()->json(['success' => false, 'message' => 'Invalid format'], 400);
        }

        return Excel::download($export, $fileName . $extension, $writerType);
    }

    /**
     * Preview import data and errors.
     */
    public function previewImport(Request $request, $type)
    {
        $request->validate([
            'file' => 'required|mimes:xlsx,csv,txt'
        ]);

        $import = null;
        switch ($type) {
            case 'users':
                $import = new UsersImport();
                break;
            case 'loans':
                $import = new \App\Imports\LoansImport();
                break;
            case 'transactions':
                $import = new \App\Imports\TransactionsImport();
                break;
            case 'activity-logs':
                $import = new \App\Imports\ActivityLogsImport();
                break;
            default:
                return response()->json(['success' => false, 'message' => 'Invalid import type'], 400);
        }

        try {
            // We use toArray to get all data for preview/validation
            $data = Excel::toArray($import, $request->file('file'));
            $rows = $data[0]; // First sheet

            $results = $import->validateData($rows);

            return response()->json([
                'success' => true,
                'total_rows' => count($rows),
                'valid_rows' => count($results['valid']),
                'error_rows' => count($results['errors']),
                'preview' => array_slice($rows, 0, 10), // Return first 10 rows for preview
                'errors' => $results['errors'],
                'duplicates' => $results['duplicates']
            ]);
        } catch (Exception $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }
    }

    /**
     * Confirm and perform the import.
     */
    public function confirmImport(Request $request, $type)
    {
        $request->validate([
            'file' => 'required|mimes:xlsx,csv,txt'
        ]);

        try {
            $import = null;
            switch ($type) {
                case 'users':
                    $import = new UsersImport();
                    break;
                case 'loans':
                    $import = new \App\Imports\LoansImport();
                    break;
                case 'transactions':
                    $import = new \App\Imports\TransactionsImport();
                    break;
                case 'activity-logs':
                    $import = new \App\Imports\ActivityLogsImport();
                    break;
                default:
                    return response()->json(['success' => false, 'message' => 'Invalid import type'], 400);
            }

            $data = Excel::toArray($import, $request->file('file'));
            $rows = $data[0] ?? [];
            $results = $import->validateData($rows);

            if (empty($results['valid'])) {
                return response()->json([
                    'success' => true,
                    'message' => 'No valid rows were available to import',
                    'imported_count' => 0,
                    'failed_count' => count($results['errors']) + count($results['duplicates'])
                ]);
            }

            Excel::import($import, $request->file('file'));

            return response()->json([
                'success' => true,
                'message' => 'Data imported successfully',
                'imported_count' => count($results['valid']),
                'failed_count' => count($results['errors']) + count($results['duplicates'])
            ]);
        } catch (Exception $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }
    }

    /**
     * Download the error report for failed rows.
     */
    public function downloadErrorReport(Request $request)
    {
        $request->validate([
            'errors' => 'required|array'
        ]);

        $export = new \App\Exports\ErrorsExport($request->errors);
        return Excel::download($export, 'import_errors_' . date('Ymd_His') . '.xlsx');
    }
}
