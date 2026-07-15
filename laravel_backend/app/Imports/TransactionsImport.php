<?php

namespace App\Imports;

use App\Models\Transaction;
use App\Models\Shareholder;
use Illuminate\Support\Facades\Validator;
use Maatwebsite\Excel\Concerns\ToCollection;
use Maatwebsite\Excel\Concerns\WithHeadingRow;
use Illuminate\Support\Collection;

class TransactionsImport implements ToCollection, WithHeadingRow
{
    public $errors = []; // ADD THIS LINE
    public $isPreview = false; // ADD THIS FLAG

    public function collection(Collection $rows)
    {
        $validated = $this->validateData($rows->toArray());

        // Store errors to the property so the controller can read it
        $this->errors = $validated['errors'];

        // Only create if NOT in preview mode
        if (!$this->isPreview) {
            foreach ($validated['valid'] as $row) {
                $this->createTransaction($row);
            }
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
                'reference_id' => 'required|string',
                'type' => 'required|in:deposit,withdrawal,payment,fee',
                'method' => 'required|in:cash,bank_transfer,online',
                'amount' => 'required|numeric|min:0',
                'status' => 'required|in:completed,pending,failed',
            ]);

            if ($validator->fails()) {
                $errors[] = [
                    'row' => $index + 2,
                    'messages' => $validator->errors()->all(),
                    'data' => $row
                ];
                continue;
            }

            // Duplicate detection by reference_id
            $existing = Transaction::where('reference_id', $row['reference_id'])->first();
            if ($existing) {
                $duplicates[] = [
                    'row' => $index + 2,
                    'message' => "Transaction with this Reference ID already exists",
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
        return !empty($row['shareholder_email']) && !empty($row['reference_id']);
    }

    private function createTransaction($row)
    {
        $shareholder = Shareholder::whereHas('user', function($q) use ($row) {
            $q->where('email', $row['shareholder_email']);
        })->first();

        if ($shareholder) {
            Transaction::create([
                'shareholder_id' => $shareholder->id,
                'reference_id' => $row['reference_id'],
                'type' => strtolower($row['type']),
                'method' => strtolower($row['method']),
                'amount' => $row['amount'],
                'status' => strtolower($row['status']),
                'date' => now(),
            ]);
        }
    }
}
