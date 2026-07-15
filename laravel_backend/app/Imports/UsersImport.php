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
    public $errors = [];
    public $isPreview = false;

    public function collection(Collection $rows)
    {
        $validated = $this->validateData($rows->toArray());
        $this->errors = $validated['errors'];

        if (!$this->isPreview) {
            foreach ($validated['valid'] as $row) {
                $this->createUser($row);
            }
        }
    }

    public function validateData(array $rows)
    {
        $valid = [];
        $errors = [];

        foreach ($rows as $index => $row) {
            // Mapping CSV keys (which include spaces) to internal keys
            $data = [
                'username'  => $row['username'] ?? null,
                'email'     => $row['email'] ?? null,
                'firstname' => $row['first_name'] ?? null,
                'lastname'  => $row['last_name'] ?? null,
                'role'      => strtolower($row['role'] ?? ''),
                'status'    => strtolower($row['status'] ?? ''),
            ];

            $validator = Validator::make($data, [
                'username'  => 'required|string',
                'email'     => 'required|email',
                'firstname' => 'required|string',
                'lastname'  => 'required|string',
                'role'      => 'required|in:admin,staff,member,shareholder',
                'status'    => 'required|in:active,inactive,suspended,pending',
            ]);

            if ($validator->fails()) {
                $errors[] = [
                    'row' => $index + 2,
                    'messages' => $validator->errors()->all(),
                    'data' => $row
                ];
                continue;
            }

            // Duplicate check
            if (User::where('username', $data['username'])->orWhere('email', $data['email'])->exists()) {
                $errors[] = [
                    'row' => $index + 2,
                    'messages' => ["Username or Email already exists."],
                    'data' => $row
                ];
                continue;
            }

            $valid[] = $data;
        }

        return ['valid' => $valid, 'errors' => $errors];
    }

    private function createUser($row)
    {
        User::create([
            'username'  => $row['username'],
            'email'     => $row['email'],
            'password'  => Hash::make('password123'),
            'firstname' => $row['firstname'],
            'lastname'  => $row['lastname'],
            'role'      => $row['role'],
            'status'    => $row['status'],
        ]);
    }
}