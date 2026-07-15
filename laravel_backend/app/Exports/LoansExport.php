<?php

namespace App\Exports;

use App\Models\Loan;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithMapping;

class LoansExport implements FromCollection, WithHeadings, WithMapping
{
    public function collection()
    {
        return Loan::with('shareholder.user')->get();
    }

    public function headings(): array
    {
        return [
            'ID',
            'Shareholder',
            'Principal Amount',
            'Interest Rate (%)',
            'Tenure (Months)',
            'Monthly Amortization',
            'Remaining Balance',
            'Status',
            'Next Repayment Date',
            'Release Date',
        ];
    }

    public function map($loan): array
    {
        return [
            $loan->id,
            $loan->shareholder?->user?->fullName ?? 'N/A',
            $loan->principal_amount,
            $loan->interest_rate,
            $loan->tenure_months,
            $loan->monthly_amortization,
            $loan->remaining_balance,
            strtoupper($loan->status),
            $loan->next_repayment_date?->toDateString() ?? 'N/A',
            $loan->release_date?->toDateTimeString() ?? 'N/A',
        ];
    }
}
