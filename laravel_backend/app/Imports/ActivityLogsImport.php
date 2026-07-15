<?php

namespace App\Imports;

use App\Models\ActivityLog;
use App\Models\User;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
use Maatwebsite\Excel\Concerns\ToCollection;
use Maatwebsite\Excel\Concerns\WithHeadingRow;
use Illuminate\Support\Collection;

class ActivityLogsImport implements ToCollection, WithHeadingRow
{
    // Property to toggle between dry-run and save
    public $isPreview = false;
    public $errors = [];

    public function collection(Collection $rows)
    {
        foreach ($rows as $index => $row) {
            // 1. Map CSV Headers to our internal logic
            // CSV Headers: Date, User, Action, Type, Details, IP Address, Device
            $mappedData = [
                'user_email'  => $row['user'] ?? null,
                'action'      => $row['action'] ?? null,
                'log_type'    => strtolower($row['type'] ?? ''),
                'description' => $row['details'] ?? null,
            ];

            // 2. Validate the mapped data
            $validator = Validator::make($mappedData, [
                'user_email' => 'required|email|exists:users,email',
                'action'     => 'required|string',
                'log_type'   => 'required|in:auth,transaction,error,access,general',
                'description'=> 'required|string',
            ]);

            if ($validator->fails()) {
                $this->errors[] = [
                    'row' => $index + 2,
                    'messages' => $validator->errors()->all()
                ];
                continue;
            }

            // 3. If NOT preview, save to database
            if (!$this->isPreview) {
                $this->createLog($mappedData);
            }
        }
    }

    private function createLog(array $data)
    {
        $user = User::where('email', $data['user_email'])->first();

        if ($user) {
            ActivityLog::create([
                'user_id'     => $user->id,
                'action'      => $data['action'],
                'log_type'    => $data['log_type'],
                'description' => $data['description'],
                'ip_address'  => request()->ip() ?? '127.0.0.1',
            ]);
        } else {
            Log::warning("Import: User not found for " . $data['user_email']);
        }
    }
}