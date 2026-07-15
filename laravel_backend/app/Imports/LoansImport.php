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
    public function collection(Collection $rows)
    {
        $validated = $this->validateData($rows->toArray());

        foreach ($validated['valid'] as $row) {
            $this->createLoan($row);
        }
    }

    public function validateData(array $rows)
    {
        $valid = [];
        $errors = [];
        $duplicates = [];

        foreach ($rows as $index => $row) {
            $validator = Validator::make($row, [
                'shareholder_email' => 'required|email|exists:users,email',
                'principal_amount' => 'required|numeric|min:0',
                'interest_rate' => 'required|numeric|min:0',
                'tenure_months' => 'required|integer|min:1',
                'status' => 'required|in:active,paid,overdue,defaulteded',
            ]);

            if ($validator->fails()) {
                $errors[] = [
                    'row' => $index + 2,
                    'messages' => $validator->errors()->all(),
                    'data' => $row
                ];
                continue;
            }

            $valid[] = $row;
        }

        return [
            'valid' => $valid,
            'errors' => $errors,
            'duplicates' => $duplicates
        ];
    }

    private function isValid($row)
    {
        return !empty($row['shareholder_email']) && isset($row['principal_amount']);
    }

    private function createLoan($row)
    {
        $shareholder = Shareholder::whereHas('user', function($q) use ($row) {
            $q->where('email', $row['shareholder_email']);
        })->first();

        if ($shareholder) {
            Loan::create([
                'shareholder_id' => $shareholder->id,
                'principal_amount' => $row['principal_amount'],
                'interest_rate' => $row['interest_rate'],
                'tenure_months' => $row['tenure_months'],
                'remaining_balance' => $row['principal_amount'],
                'status' => strtolower($row['status']),
                'next_repayment_date' => now()->addMonth(),
                'release_date' => now(),
            ]);
        }
    }
}
