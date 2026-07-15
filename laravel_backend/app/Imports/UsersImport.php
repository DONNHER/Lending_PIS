<?php

namespace App\Imports;

use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Maatwebsite\Excel\Concerns\ToModel;
use Maatwebsite\Excel\Concerns\WithHeadingRow;
use Illuminate\Support\Collection;
use Maatwebsite\Excel\Concerns\ToCollection;

class UsersImport implements ToCollection, WithHeadingRow
{
    /**
     * Used for actual import.
     */
    public function collection(Collection $rows)
    {
        $validated = $this->validateData($rows->toArray());

        foreach ($validated['valid'] as $row) {
            $this->createUser($row);
        }
    }

    /**
     * Validate data and find duplicates/errors.
     */
    public function validateData(array $rows)
    {
        $valid = [];
        $errors = [];
        $duplicates = [];

        foreach ($rows as $index => $row) {
            $validator = Validator::make($row, [
                'username' => 'required|string',
                'email' => 'required|email',
                'firstname' => 'required|string',
                'lastname' => 'required|string',
                'role' => 'required|in:admin,staff,member',
                'status' => 'required|in:active,inactive,suspended',
            ]);

            if ($validator->fails()) {
                $errors[] = [
                    'row' => $index + 2, // +1 for 0-index, +1 for header
                    'messages' => $validator->errors()->all(),
                    'data' => $row
                ];
                continue;
            }

            // Duplicate detection
            $existing = User::where('username', $row['username'])
                ->orWhere('email', $row['email'])
                ->first();

            if ($existing) {
                $duplicates[] = [
                    'row' => $index + 2,
                    'message' => "User with this username or email already exists (ID: {$existing->id})",
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
        return !empty($row['username']) && !empty($row['email']) && !empty($row['firstname']) && !empty($row['lastname']);
    }

    private function createUser($row)
    {
        User::create([
            'username' => $row['username'],
            'email' => $row['email'],
            'password' => Hash::make('password123'), // Default password
            'firstname' => $row['firstname'],
            'lastname' => $row['lastname'],
            'role' => strtolower($row['role']),
            'status' => strtolower($row['status']),
        ]);
    }
}
