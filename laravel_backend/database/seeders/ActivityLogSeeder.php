<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\ActivityLog;
use App\Models\User;
use Illuminate\Support\Str;

class ActivityLogSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $admin = User::where('role', User::ROLE_ADMIN)->first();
        $member = User::where('role', User::ROLE_MEMBER)->first();

        if (!$admin) return;

        $logs = [
            [
                'user_id' => $admin->id,
                'action' => 'User Login',
                'log_type' => ActivityLog::TYPE_AUTH,
                'description' => 'Administrator logged into the system.',
                'ip_address' => '192.168.1.105',
                'device_info' => 'Chrome on Windows 11 (Desktop)',
            ],
            [
                'user_id' => $admin->id,
                'action' => 'User Logout',
                'log_type' => ActivityLog::TYPE_AUTH,
                'description' => 'Administrator logged out of the session.',
                'ip_address' => '192.168.1.105',
                'device_info' => 'Chrome on Windows 11 (Desktop)',
            ],
            [
                'user_id' => $admin->id,
                'action' => 'Failed Login Attempt',
                'log_type' => ActivityLog::TYPE_AUTH,
                'description' => 'Multiple failed attempts detected for account: ' . $admin->email,
                'ip_address' => '45.12.33.10',
                'device_info' => 'Unknown Device (Firefox / Linux)',
                'is_suspicious' => true,
            ],
        ];

        if ($member) {
            $logs[] = [
                'user_id' => $member->id,
                'action' => 'User Login',
                'log_type' => ActivityLog::TYPE_AUTH,
                'description' => 'Member logged in via mobile app.',
                'ip_address' => '10.0.0.12',
                'device_info' => 'Lending App on Android 14 (Samsung S24)',
            ];
        }

        foreach ($logs as $logData) {
            ActivityLog::create($logData);
        }

        // Add some general logs to test filtering
        ActivityLog::create([
            'user_id' => $admin->id,
            'action' => 'System Update',
            'log_type' => ActivityLog::TYPE_GENERAL,
            'description' => 'Maintenance routine completed successfully.',
            'ip_address' => '127.0.0.1',
            'device_info' => 'System Console',
        ]);
    }
}
