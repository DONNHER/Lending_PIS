<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database with rubric-compliant test accounts.
     */
    public function run(): void
    {
        // 1. ADMIN ACCOUNT
        User::updateOrCreate(
            ['email' => 'admin@test.com'],
            [
                'username' => 'admin_test',
                'password' => Hash::make('P@ssword123!'),
                'firstname' => 'System',
                'lastname' => 'Administrator',
                'role' => User::ROLE_ADMIN,
                'status' => User::STATUS_ACTIVE,
                'mfa_enabled' => true,
            ]
        );

        // 2. STAFF ACCOUNT
        User::updateOrCreate(
            ['email' => 'staff@test.com'],
            [
                'username' => 'staff_test',
                'password' => Hash::make('P@ssword123!'),
                'firstname' => 'Inventory',
                'lastname' => 'Officer',
                'role' => User::ROLE_STAFF,
                'status' => User::STATUS_ACTIVE,
                'mfa_enabled' => false, // Easier for demo purposes
            ]
        );

        // 3. MEMBER ACCOUNT
        User::updateOrCreate(
            ['email' => 'member@test.com'],
            [
                'username' => 'member_test',
                'password' => Hash::make('P@ssword123!'),
                'firstname' => 'Shareholder',
                'lastname' => 'Member',
                'role' => User::ROLE_MEMBER,
                'status' => User::STATUS_ACTIVE,
                'mfa_enabled' => false,
            ]
        );
    }
}
