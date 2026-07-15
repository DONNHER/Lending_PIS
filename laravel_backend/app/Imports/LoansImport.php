<?php

namespace App\Imports;

use App\Models\Loan;
use App\Models\Shareholder;
use App\Models\User;
use Illuminate\Support\Facades\Validator;
use Maatwebsite\Excel\Concerns\ToCollection;
use Maatwebsite\Excel\Concerns\WithHeadingRow;
use Illuminate\Support\Collection;

class LoansImport implements ToCollection, WithHeadingRow
{
    public $errors = [];
    public $isPreview = false;

    public function collection(Collection $rows)
    {
        foreach ($rows as $index => $row) {
            // Normalize CSV keys to match our logic
            $data = $row->toArray();

            // Validate (Accepting both names and emails if needed)
            $validator = Validator::make($data, [
                'shareholder' => 'required', // Now accepts the name column
                'principal_amount' => 'required|numeric|min:0',
                'interest_rate' => 'required|numeric|min:0',
                'tenure_months' => 'required|integer|min:1',
                'status' => 'required',
            ]);

            if ($validator->fails()) {
                $this->errors[] = [
                    'row' => $index + 2,
                    'messages' => $validator->errors()->all(),
                    'data' => $data
                ];
                continue;
            }

            if (!$this->isPreview) {
                $this->createLoan($data);
            }
        }
    }

    private function createLoan($row)
    {
        // Search by shareholder name (firstname + lastname)
        $shareholder = Shareholder::whereHas('user', function($q) use ($row) {
            $q->whereRaw("CONCAT(firstname, ' ', lastname) LIKE ?", ["%{$row['shareholder']}%"]);
        })->first();

        if ($shareholder) {
            // Map 'FULLY PAID' to 'paid', etc.
            $statusMap = ['FULLY PAID' => 'paid', 'ACTIVE' => 'active'];
            $status = $statusMap[strtoupper($row['status'])] ?? strtolower($row['status']);

            Loan::updateOrCreate(
                ['shareholder_id' => $shareholder->id, 'principal_amount' => $row['principal_amount']],
                [
                    'interest_rate' => $row['interest_rate'],
                    'tenure_months' => $row['tenure_months'],
                    'remaining_balance' => $row['remaining_balance'] ?? $row['principal_amount'],
                    'status' => $status,
                    'release_date' => now(),
                ]
            );
        }
    }
}