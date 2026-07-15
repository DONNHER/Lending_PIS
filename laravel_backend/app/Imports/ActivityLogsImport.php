<?php

namespace App\Imports;

use App\Models\ActivityLog;
use App\Models\User;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
use Maatwebsite\Excel\Concerns\ToCollection;
use Maatwebsite\Excel\Concerns\WithHeadingRow;
use Illuminate\Support\Collection; // Ensure this is the only Collection import

class ActivityLogsImport implements ToCollection, WithHeadingRow
{
    public $isPreview = false;
    public $errors = [];

    public function collection(Collection $rows)
    {
        foreach ($rows as $index => $row) {
            // Map CSV headers (Date, User, Action, Type, Details) to logic keys
            $mappedData = [
                'name'        => $row['user'] ?? null,
                'action'      => $row['action'] ?? null,
                'log_type'    => strtolower($row['type'] ?? ''),
                'description' => $row['details'] ?? null,
            ];

            // Validation: Ensure the user 'name' exists in the users table
            $validator = Validator::make($mappedData, [
                'name'        => 'required|string|exists:users,name',
                'action'      => 'required|string',
                'log_type'    => 'required|in:auth,transaction,error,access,general',
                'description' => 'required|string',
            ]);

            if ($validator->fails()) {
                $this->errors[] = [
                    'row' => $index + 2,
                    'messages' => $validator->errors()->all()
                ];
                continue;
            }

            if (!$this->isPreview) {
                $this->createLog($mappedData);
            }
        }
    }

    private function createLog(array $data)
    {
        $user = User::where('name', $data['name'])->first();

        if ($user) {
            ActivityLog::create([
                'user_id'     => $user->id,
                'action'      => $data['action'],
                'log_type'    => $data['log_type'],
                'description' => $data['description'],
                'ip_address'  => request()->ip() ?? '127.0.0.1',
            ]);
        } else {
            Log::warning("Import: User not found for name: " . $data['name']);
        }
    }
}