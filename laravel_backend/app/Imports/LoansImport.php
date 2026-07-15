<?php

namespace App\Imports;

use App\Models\Loan;
use App\Models\Shareholder;
use Illuminate\Support\Facades\Validator;
use Maatwebsite\Excel\Concerns\ToCollection;
use Maatwebsite\Excel\Concerns\WithHeadingRow;
use Illuminate\Support\Collection;

class LoansImport implements ToCollection, WithHeadingRow
{
    public $errors = [];
    public $isPreview = false; // Add this flag

    public function collection(Collection $rows)
    {
        foreach ($rows as $index => $row) {
            $validator = Validator::make($row->toArray(), [
                'shareholder_email' => 'required|email|exists:users,email',
                'principal_amount' => 'required|numeric|min:0',
                'interest_rate' => 'required|numeric|min:0',
                'tenure_months' => 'required|integer|min:1',
                'status' => 'required|in:active,paid,overdue,defaulted',
            ]);

            if ($validator->fails()) {
                $this->errors[] = [
                    'row' => $index + 2,
                    'messages' => $validator->errors()->all(),
                    'data' => $row->toArray()
                ];
                continue;
            }

            // ONLY CREATE if NOT in preview mode
            if (!$this->isPreview) {
                $this->createLoan($row->toArray());
            }
        }
    }

    private function createLoan($row)
    {
        $shareholder = Shareholder::whereHas('user', function($q) use ($row) {
            $q->where('email', $row['shareholder_email']);
        })->first();

        if ($shareholder) {
            return Loan::updateOrCreate(
                ['shareholder_id' => $shareholder->id, 'principal_amount' => $row['principal_amount']],
                [
                    'interest_rate' => $row['interest_rate'],
                    'tenure_months' => $row['tenure_months'],
                    'remaining_balance' => $row['principal_amount'],
                    'status' => strtolower($row['status']),
                    'next_repayment_date' => now()->addMonth(),
                    'release_date' => now(),
                ]
            );
        }
    }
}