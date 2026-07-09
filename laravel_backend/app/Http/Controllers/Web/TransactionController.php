<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Transaction;
use Illuminate\Http\Request;

class TransactionController extends Controller
{
    public function index(Request $request)
    {
        $query = Transaction::with('shareholder');

        // Apply advanced controls from trait
        $query->applyControls($request, ['shareholder.firstname', 'shareholder.lastname', 'type', 'description']);

        if ($request->filled('type') && $request->type !== 'All Types') {
            $query->where('type', $request->type);
        }

        if ($request->has('export')) {
            return $this->export($request);
        }

        $perPage = $request->get('per_page', 15);
        $transactions = $query->paginate($perPage)->withQueryString();

        return view('admin.transactions.index', compact('transactions'));
    }

    public function export(Request $request)
    {
        $format = $request->get('format', 'csv');
        $transactions = Transaction::with('shareholder')->latest('date')->get();

        if ($format === 'csv') {
            $headers = [
                "Content-type"        => "text/csv",
                "Content-Disposition" => "attachment; filename=transactions_export_" . date('Y-m-d') . ".csv",
                "Pragma"              => "no-cache",
                "Cache-Control"       => "must-revalidate, post-check=0, pre-check=0",
                "Expires"             => "0"
            ];

            $callback = function() use($transactions) {
                $file = fopen('php://output', 'w');
                fputcsv($file, ['Date', 'ID', 'Shareholder', 'Type', 'Amount', 'Status', 'Description']);

                foreach ($transactions as $tx) {
                    fputcsv($file, [
                        $tx->date->format('Y-m-d H:i'),
                        $tx->id,
                        $tx->shareholder->firstname . ' ' . $tx->shareholder->lastname,
                        $tx->type,
                        $tx->amount,
                        $tx->status,
                        $tx->description
                    ]);
                }
                fclose($file);
            };

            return response()->stream($callback, 200, $headers);
        }

        // Print View
        return view('admin.transactions.print', compact('transactions'));
    }
}
