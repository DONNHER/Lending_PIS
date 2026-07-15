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
    public $errors = [];
    public $isPreview = false;

    public function collection(Collection $rows)
    {
        $validated = $this->validateData($rows->toArray());

        $this->errors = $validated['errors'];

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
            // --- DATA MAPPING LAYER ---
            // Maps your CSV headers/values to the system's expected format
            $data = [
                'shareholder_email' => $row['client_email'] ?? $row['client'] ?? null,
                'reference_id'      => (string)($row['transaction_id'] ?? ''),
                'type'              => $this->mapCsvType($row['type'] ?? ''),
                'method'            => strtolower($row['method'] ?? ''),
                'amount'            => $row['amount'] ?? 0,
                'status'            => $this->mapCsvStatus($row['status'] ?? ''),
            ];

            $validator = Validator::make($data, [
                'shareholder_email' => 'required|email|exists:users,email',
                'reference_id'      => 'required|string',
                'type'              => 'required|in:deposit,withdrawal,payment,fee',
                'method'            => 'required|in:cash,bank_transfer,online',
                'amount'            => 'required|numeric|min:0',
                'status'            => 'required|in:completed,pending,failed',
            ]);

            if ($validator->fails()) {
                $errors[] = [
                    'row' => $index + 2,
                    'messages' => $validator->errors()->all(),
                    'data' => $row
                ];
                continue;
            }

            $existing = Transaction::where('reference_id', $data['reference_id'])->first();
            if ($existing) {
                $duplicates[] = [
                    'row' => $index + 2,
                    'message' => "Transaction with this Reference ID already exists",
                    'data' => $row
                ];
                continue;
            }

            $valid[] = $data;
        }

        return ['valid' => $valid, 'errors' => $errors, 'duplicates' => $duplicates];
    }

    private function mapCsvType($type) {
        $map = [
            'loan repayment' => 'payment',
            'capital contribution' => 'deposit',
            'loan disbursement' => 'withdrawal'
        ];
        return $map[strtolower($type)] ?? 'fee';
    }

    private function mapCsvStatus($status) {
        return strtolower($status) === 'successful' ? 'completed' : 'failed';
    }

    private function createTransaction($row)
    {
        $shareholder = Shareholder::whereHas('user', function($q) use ($row) {
            $q->where('email', $row['shareholder_email']);
        })->first();

        if ($shareholder) {
            Transaction::create([
                'shareholder_id' => $shareholder->id,
                'reference_id'   => $row['reference_id'],
                'type'           => $row['type'],
                'method'         => $row['method'],
                'amount'         => $row['amount'],
                'status'         => $row['status'],
                'date'           => now(),
            ]);
        }
    }
}