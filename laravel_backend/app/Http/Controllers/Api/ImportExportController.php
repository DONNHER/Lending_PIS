<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Maatwebsite\Excel\Facades\Excel;
use Barryvdh\DomPDF\Facade\Pdf;
use Carbon\Carbon;

// Exports
use App\Exports\TransactionsExport;
use App\Exports\UsersExport;
use App\Exports\LoansExport;
use App\Exports\ActivityLogsExport;
use App\Exports\ErrorsExport;

// Models
use App\Models\Transaction;
use App\Models\User;
use App\Models\Loan;
use App\Models\ActivityLog;

class ImportExportController extends Controller
{
    public function export(Request $request, $type, $format)
    {
        $type = strtolower(trim($type));
        $format = strtolower(trim($format));
        $filename = $type . '_report_' . now()->format('Ymd_His');

        // 1. HANDLE EXCEL / CSV EXPORTS
        if (in_array($format, ['xlsx', 'csv'])) {
            switch ($type) {
                case 'transactions': return Excel::download(new TransactionsExport(), $filename . '.' . $format);
                case 'users':        return Excel::download(new UsersExport(), $filename . '.' . $format);
                case 'loans':        return Excel::download(new LoansExport(), $filename . '.' . $format);
                case 'activitylogs': return Excel::download(new ActivityLogsExport(), $filename . '.' . $format);
                default:
                    return response()->json(['error' => "Export type [{$type}] not supported for Excel."], 400);
            }
        }

        // 2. HANDLE PDF EXPORTS
        if ($format === 'pdf') {
            $viewName = 'reports.generic';

            $data = [
                'title' => ucwords(str_replace('-', ' ', $type)) . ' Report',
                'subtitle' => 'System Audit & Ledger',
                'generatedAt' => now()->toDateTimeString(),
            ];

            if ($type === 'transactions') {
                $data['headers'] = ['ID', 'Reference', 'Shareholder', 'Type', 'Method', 'Amount', 'Status', 'Date'];
                $data['rows'] = Transaction::with('shareholder.user')->orderBy('date', 'desc')->get()->map(fn($tx) => [
                    'id' => $tx->id,
                    'reference_id' => $tx->reference_id ?? 'N/A',
                    'shareholder' => $tx->shareholder?->user?->fullName ?? 'N/A',
                    'type' => strtoupper($tx->type ?? 'N/A'),
                    'method' => strtoupper($tx->method ?? 'N/A'),
                    'amount' => 'PHP ' . number_format($tx->amount ?? 0, 2),
                    'status' => strtoupper($tx->status ?? 'N/A'),
                    'date' => $tx->date ? Carbon::parse($tx->date)->format('Y-m-d') : 'N/A',
                ])->toArray();
                $data['summary'] = [['label' => 'Total Transactions', 'value' => count($data['rows'])]];
            }
            elseif ($type === 'users') {
                $data['headers'] = ['ID', 'Username', 'Full Name', 'Email', 'Role', 'Status', 'Verified', 'Joined'];
                $data['rows'] = User::orderBy('id', 'desc')->get()->map(fn($u) => [
                    'id' => $u->id,
                    'reference_id' => $u->username ?? 'N/A',
                    'shareholder' => trim(($u->firstname ?? '') . ' ' . ($u->lastname ?? '')),
                    'type' => $u->email,
                    'method' => $u->role ?? 'USER',
                    'amount' => $u->status ?? 'ACTIVE',
                    'status' => $u->email_verified_at ? 'VERIFIED' : 'PENDING',
                    'date' => $u->created_at?->format('Y-m-d') ?? 'N/A',
                ])->toArray();
                $data['summary'] = [['label' => 'Total Users', 'value' => count($data['rows'])]];
            }
            elseif ($type === 'loans') {
                $data['headers'] = ['ID', 'Shareholder', 'Principal', 'Rate (%)', 'Tenure', 'Amortization', 'Balance', 'Status'];
                $data['rows'] = Loan::with('shareholder.user')->orderBy('id', 'desc')->get()->map(fn($l) => [
                    'id' => $l->id,
                    'reference_id' => $l->shareholder?->user?->fullName ?? 'N/A',
                    'shareholder' => number_format($l->principal_amount ?? 0, 2),
                    'type' => $l->interest_rate . '%',
                    'method' => $l->tenure_months . ' mos',
                    'amount' => number_format($l->monthly_amortization ?? 0, 2),
                    'status' => number_format($l->remaining_balance ?? 0, 2),
                    'date' => strtoupper($l->status ?? 'PENDING'),
                ])->toArray();
                $data['summary'] = [['label' => 'Total Active Loans', 'value' => count($data['rows'])]];
            }
            else {
                return response()->json(['error' => "PDF formatting for [{$type}] not implemented."], 400);
            }

            $pdf = Pdf::loadView($viewName, $data);
            return $pdf->setPaper('a4', 'portrait')->stream($filename . '.pdf');
        }

        return response()->json(['error' => 'Unsupported format.'], 400);
    }
}