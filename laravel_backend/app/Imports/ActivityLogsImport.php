<?php

namespace App\Imports;

use App\Models\ActivityLog;
use App\Models\User;
use Illuminate\Support\Facades\Validator;
use Maatwebsite\Excel\Concerns\ToCollection;
use Maatwebsite\Excel\Concerns\WithHeadingRow;
use Illuminate\Support\Collection;

class ActivityLogsImport implements ToCollection, WithHeadingRow
{
    public function collection(Collection $rows)
    {
        $validated = $this->validateData($rows->toArray());

        foreach ($validated['valid'] as $row) {
            $this->createLog($row);
        }
    }

    public function validateData(array $rows)
    {
        $valid = [];
        $errors = [];
        $duplicates = [];

        foreach ($rows as $index => $row) {
            $validator = Validator::make($row, [
                'user_email' => 'required|email|exists:users,email',
                'action' => 'required|string',
                'log_type' => 'required|in:auth,transaction,error,access,general',
                'description' => 'required|string',
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
        return !empty($row['user_email']) && !empty($row['action']);
    }

    private function createLog($row)
    {
        $user = User::where('email', $row['user_email'])->first();

        if ($user) {
            ActivityLog::create([
                'user_id' => $user->id,
                'action' => $row['action'],
                'log_type' => strtolower($row['log_type']),
                'description' => $row['description'],
                'ip_address' => request()->ip() ?? '127.0.0.1',
            ]);
        }
    }
}
