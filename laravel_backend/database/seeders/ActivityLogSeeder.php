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
        ActivityLog::create([
            'user_id' => $admin->id,
            'shareholder_id' => $member ? $member->id : null,
            'action' => 'Update User Status',
            'log_type' => ActivityLog::TYPE_TRANSACTION,
            'description' => 'Admin updated member status.',
            'ip_address' => '192.168.1.105',
            'device_info' => 'Chrome on Windows 11',
            'old_values' => ['status' => 'inactive', 'remarks' => 'None'],
            'new_values' => ['status' => 'active', 'remarks' => 'Documentation verified'],
        ]);
            [
                'user_id' => $admin->id,
                'action' => 'Interest Rate Change',
                'log_type' => ActivityLog::TYPE_TRANSACTION,
                'description' => 'Global interest rate adjusted for inflation.',
                'ip_address' => '192.168.1.105',
                'device_info' => 'Admin Dashboard (Web)',
                'old_values' => ['rate' => '3.0%', 'effective_date' => '2024-01-01'],
                'new_values' => ['rate' => '3.5%', 'effective_date' => '2026-07-14'],
            ],
            [
                'user_id' => $admin->id,
                'action' => 'Create New Inventory Item',
                'log_type' => ActivityLog::TYPE_TRANSACTION,
                'description' => 'Added new product to grocery inventory.',
                'ip_address' => '192.168.1.105',
                'device_info' => 'Chrome on Windows 11',
                'old_values' => null,
                'new_values' => [
                    'sku' => 'GROC-001',
                    'name' => 'Organic Rice 5kg',
                    'price' => '250.00',
                    'stock' => 50,
                    'category' => 'Grains'
                ],
            ],
            [
                'user_id' => $admin->id,
                'action' => 'Delete Obsolete Product',
                'log_type' => ActivityLog::TYPE_TRANSACTION,
                'description' => 'Removed discontinued item from catalog.',
                'ip_address' => '192.168.1.105',
                'device_info' => 'Chrome on Windows 11',
                'old_values' => [
                    'sku' => 'OLD-999',
                    'name' => 'Legacy Flour',
                    'status' => 'discontinued'
                ],
                'new_values' => null,
            ],
            [
                'user_id' => $admin->id,
                'action' => 'Bulk User Update',
                'log_type' => ActivityLog::TYPE_TRANSACTION,
                'description' => 'Modified multiple user account security settings.',
                'ip_address' => '192.168.1.105',
                'device_info' => 'System Script',
                'old_values' => [
                    'mfa_required' => false,
                    'password_expiry_days' => 90
                ],
                'new_values' => [
                    'mfa_required' => true,
                    'password_expiry_days' => 30
                ],
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

        // Add Error logs with stack traces
        ActivityLog::create([
            'user_id' => null,
            'action' => 'Unhandled Exception',
            'log_type' => ActivityLog::TYPE_ERROR,
            'description' => 'Call to undefined method App\Services\LendingService::calculateCompoundInterest()',
            'ip_address' => '127.0.0.1',
            'device_info' => 'Laravel Framework 10.x',
            'stack_trace' => "#0 C:\\Users\\Grace Anne\\Desktop\\LARAVEL\\capstone-application\\laravel_backend\\app\\Http\\Controllers\\Api\\LoanController.php(45): App\\Services\\LendingService->calculateCompoundInterest()\n#1 [internal function]: App\\Http\\Controllers\\Api\\LoanController->store(Object(Illuminate\\Http\\Request))\n#2 C:\\Users\\Grace Anne\\Desktop\\LARAVEL\\capstone-application\\laravel_backend\\vendor\\laravel\\framework\\src\\Illuminate\\Routing\\Controller.php(54): call_user_func_array(Array, Array)\n#3 C:\\Users\\Grace Anne\\Desktop\\LARAVEL\\capstone-application\\laravel_backend\\vendor\\laravel\\framework\\src\\Illuminate\\Routing\\ControllerDispatcher.php(43): Illuminate\\Routing\\Controller->callAction('store', Array)\n#4 C:\\Users\\Grace Anne\\Desktop\\LARAVEL\\capstone-application\\laravel_backend\\vendor\\laravel\\framework\\src\\Illuminate\\Routing\\Route.php(259): Illuminate\\Routing\\ControllerDispatcher->dispatch(Object(Illuminate\\Routing\\Route), Object(App\\Http\\Controllers\\Api\\LoanController), 'store')",
        ]);

        ActivityLog::create([
            'user_id' => $admin->id,
            'action' => 'Database Query Error',
            'log_type' => ActivityLog::TYPE_ERROR,
            'description' => 'SQLSTATE[42S22]: Column not found: 1054 Unknown column \'invalid_column\' in \'where clause\'',
            'ip_address' => '192.168.1.105',
            'device_info' => 'Chrome on Windows 11',
            'stack_trace' => "Illuminate\\Database\\QueryException: SQLSTATE[42S22]: Column not found: 1054 Unknown column 'invalid_column' in 'where clause' (SQL: select * from `loans` where `invalid_column` = 1)\n#0 C:\\Users\\Grace Anne\\Desktop\\LARAVEL\\capstone-application\\laravel_backend\\vendor\\laravel\\framework\\src\\Illuminate\\Database\\Connection.php(759): Illuminate\\Database\\Connection->runQueryCallback('select * from `...', Array, Object(Closure))\n#1 C:\\Users\\Grace Anne\\Desktop\\LARAVEL\\capstone-application\\laravel_backend\\vendor\\laravel\\framework\\src\\Illuminate\\Database\\Connection.php(719): Illuminate\\Database\\Connection->run('select * from `...', Array, Object(Closure))\n#2 C:\\Users\\Grace Anne\\Desktop\\LARAVEL\\capstone-application\\laravel_backend\\vendor\\laravel\\framework\\src\\Illuminate\\Database\\Connection.php(384): Illuminate\\Database\\Connection->select('select * from `...', Array, true)",
        ]);

        // Access Logs - Page Visits
        ActivityLog::create([
            'user_id' => $admin->id,
            'action' => 'Page Visit',
            'log_type' => ActivityLog::TYPE_ACCESS,
            'description' => 'Admin visited the Loan Management dashboard.',
            'ip_address' => '192.168.1.105',
            'device_info' => 'Chrome on Windows 11',
        ]);

        ActivityLog::create([
            'user_id' => $admin->id,
            'action' => 'Page Visit',
            'log_type' => ActivityLog::TYPE_ACCESS,
            'description' => 'Admin accessed System Settings > Interest Management.',
            'ip_address' => '192.168.1.105',
            'device_info' => 'Chrome on Windows 11',
        ]);

        // Access Logs - Feature Usage
        ActivityLog::create([
            'user_id' => $admin->id,
            'action' => 'Feature Usage',
            'log_type' => ActivityLog::TYPE_ACCESS,
            'description' => 'User exported monthly loan report to PDF.',
            'ip_address' => '192.168.1.105',
            'device_info' => 'Chrome on Windows 11',
        ]);

        ActivityLog::create([
            'user_id' => $member->id,
            'action' => 'Feature Usage',
            'log_type' => ActivityLog::TYPE_ACCESS,
            'description' => 'Member used the Loan Calculator tool.',
            'ip_address' => '10.0.0.12',
            'device_info' => 'Lending App on Android 14',
        ]);
    }
}
