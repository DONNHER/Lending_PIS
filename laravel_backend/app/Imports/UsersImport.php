<?php

namespace App\Imports;

use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Maatwebsite\Excel\Concerns\ToCollection;
use Maatwebsite\Excel\Concerns\WithHeadingRow;
use Illuminate\Support\Collection;

class UsersImport implements ToCollection, WithHeadingRow
{
    // Required properties for the Controller to communicate with this class
    public $errors = [];
    public $isPreview = false;

    /**
     * Entry point for Excel import
     */
    public function collection(Collection $rows)
    {
        $validated = $this->validateData($rows->toArray());

        // Pass errors back to the controller's response
        $this->errors = $validated['errors'];

        // Only persist to the database if NOT in preview mode
        if (!$this->isPreview) {
            foreach ($validated['valid'] as $row) {
                $this->createUser($row);
            }
        }
    }

    /**
     * Validate data and identify errors/duplicates
     */
    public function validateData(array $rows)
    {
        $valid = [];
        $errors = [];

        foreach ($rows as $index => $row) {
            $validator = Validator::make($row, [
                'username'  => 'required|string',
                'email'     => 'required|email',
                'firstname' => 'required|string',
                'lastname'  => 'required|string',
                'role'      => 'required|in:admin,staff,member',
                'status'    => 'required|in:active,inactive,suspended',
            ]);

            if ($validator->fails()) {
                $errors[] = [
                    'row' => $index + 2, // Accounting for header row
                    'messages' => $validator->errors()->all(),
                    'data' => $row
                ];
                continue;
            }

            // Duplicate detection logic
            $existing = User::where('username', $row['username'])
                ->orWhere('email', $row['email'])
                ->first();

            if ($existing) {
                $errors[] = [
                    'row' => $index + 2,
                    'messages' => ["User with this username or email already exists (ID: {$existing->id})"],
                    'data' => $row
                ];
                continue;
            }

            $valid[] = $row;
        }

        return ['valid' => $valid, 'errors' => $errors];
    }

    /**
     * Create the user record
     */
    private function createUser($row)
    {
        User::create([
            'username'  => $row['username'],
            'email'     => $row['email'],
            'password'  => Hash::make('password123'), // Default password
            'firstname' => $row['firstname'],
            'lastname'  => $row['lastname'],
            'role'      => strtolower($row['role']),
            'status'    => strtolower($row['status']),
        ]);
    }
}