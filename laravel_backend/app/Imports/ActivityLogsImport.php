<?php

namespace App\Imports;

use App\Models\ActivityLog;
use App\Models\User;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
use Maatwebsite\Excel\Concerns\ToCollection;
use Maatwebsite\Excel\Concerns\WithHeadingRow;
use Illuminate\Collection;

class ActivityLogsImport implements ToCollection, WithHeadingRow
{
    public $isPreview = false;
    public $errors = [];

    public function collection(Collection $rows)
    {
        foreach ($rows as $index => $row) {
            // Mapping CSV headers ("User", "Action", "Type", "Details")
            $mappedData = [
                'name'        => $row['user'] ?? null,
                'action'      => $row['action'] ?? null,
                'log_type'    => strtolower($row['type'] ?? ''),
                'description' => $row['details'] ?? null,
            ];

            // Validation: Changed 'user_email' to 'name' and rule to 'exists:users,name'
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
        // Lookup user by name as it appears in the CSV
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