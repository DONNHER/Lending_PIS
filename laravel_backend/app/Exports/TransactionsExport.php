<?php

namespace App\Exports;

use App\Models\Transaction;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithMapping;

class TransactionsExport implements FromCollection, WithHeadings, WithMapping
{
    public function collection()
    {
        return Transaction::with('shareholder.user')->get();
    }

    public function headings(): array
    {
        return [
            'ID',
            'Reference ID',
            'Shareholder',
            'Type',
            'Method',
            'Amount',
            'Status',
            'Date',
        ];
    }

    public function map($transaction): array
    {
        return [
            $transaction->id,
            $transaction->reference_id,
            $transaction->shareholder?->user?->fullName ?? 'N/A',
            strtoupper($transaction->type),
            strtoupper($transaction->method),
            $transaction->amount,
            strtoupper($transaction->status),
            $transaction->date->toDateTimeString(),
        ];
    }
}
