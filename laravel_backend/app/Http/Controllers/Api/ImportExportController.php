<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Exports\TransactionsExport;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Http\Request;
use Maatwebsite\Excel\Facades\Excel;
use Barryvdh\DomPDF\Facade\Pdf;

class ImportExportController extends Controller
{
    /**
     * Handle multi-format transactional data exports safely.
     */
    public function export(Request $request, $type, $format)
    {
        $type = strtolower($type);
        $format = strtolower($format);

        // 1. HANDLE EXCEL / CSV FORMATS via Maatwebsite Excel Package
        if (in_array($format, ['xlsx', 'csv'])) {
            $filename = $type . '_export_' . now()->format('Ymd_His') . '.' . $format;

            if ($type === 'transactions') {
                return Excel::download(new TransactionsExport, $filename);
            }

            return Excel::download(new TransactionsExport, $filename);
        }

        // 2. HANDLE PROFESSIONAL PDF TEMPLATE LOGIC via DomPDF
        if ($format === 'pdf') {
            if ($type === 'transactions') {
                // 🎯 FIX: Changed sorting column from 'created_at' to 'date' to fix pgsql database crash
                $transactions = Transaction::with('shareholder.user')->orderBy('date', 'desc')->get();

                $rows = [];
                foreach ($transactions as $tx) {
                    $rows[] = [
                        'id' => $tx->id,
                        'reference_id' => $tx->reference_id ?? 'N/A',
                        'shareholder' => $tx->shareholder?->user?->fullName ?? 'N/A',
                        'type' => strtoupper($tx->type ?? 'N/A'),
                        'method' => strtoupper($tx->method ?? 'N/A'),
                        'amount' => 'PHP ' . number_format($tx->amount, 2),
                        'status' => strtoupper($tx->status),
                        'date' => $tx->date ? $tx->date->toDateTimeString() : now()->toDateTimeString(),
                    ];
                }

                // 🎯 FIX: Changed view string structure target name to match your file structure path fallback safely
                $viewName = view()->exists('exports.report') ? 'exports.report' : 'exports.transactions-pdf';

                $pdf = Pdf::loadView($viewName, [
                    'title' => 'Transaction History Ledger',
                    'subtitle' => 'System Export Audit Log',
                    'generatedAt' => now()->toDateTimeString(),
                    'headers' => ['ID', 'Reference ID', 'Shareholder', 'Type', 'Method', 'Amount', 'Status', 'Date'],
                    'rows' => $rows,
                    'summary' => [
                        ['label' => 'Total Record Count', 'value' => count($rows)],
                    ]
                ]);

                $pdf->setPaper('a4', 'portrait');
                return $pdf->stream('transactions_' . now()->format('Ymd_His') . '.pdf');
            }

            if ($type === 'users') {
                // 🎯 FIX: Use sorting parameters safe for standard application default schemes
                $users = User::orderBy('id', 'desc')->get();

                $rows = [];
                foreach ($users as $user) {
                    $rows[] = [
                        'id' => $user->id,
                        'reference_id' => $user->email,
                        'shareholder' => $user->name,
                        'type' => $user->role ?? 'USER',
                        'method' => $user->status ?? 'ACTIVE',
                        'amount' => $user->phone_number ?? 'N/A',
                        'status' => $user->email_verified_at ? 'VERIFIED' : 'PENDING',
                        'date' => $user->created_at ? $user->created_at->toDateTimeString() : now()->toDateTimeString(),
                    ];
                }

                $viewName = view()->exists('exports.report') ? 'exports.report' : 'exports.transactions-pdf';

                $pdf = Pdf::loadView($viewName, [
                    'title' => 'User Directory Report',
                    'subtitle' => 'Account System Records Management',
                    'generatedAt' => now()->toDateTimeString(),
                    'headers' => ['User ID', 'Email Address', 'Full Name', 'Role System', 'Account Status', 'Phone Contact', 'Verification Status', 'Registration Date'],
                    'rows' => $rows,
                    'summary' => [
                        ['label' => 'Total Registered Users', 'value' => count($rows)],
                    ]
                ]);

                $pdf->setPaper('a4', 'portrait');
                return $pdf->stream('users_' . now()->format('Ymd_His') . '.pdf');
            }
        }

        return response()->json(['error' => 'Format or Type signature not supported'], 400);
    }
}