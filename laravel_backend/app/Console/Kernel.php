<?php

namespace App\Console;

use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Foundation\Console\Kernel as ConsoleKernel;
use App\Models\ActivityLog;
use App\Models\SiteSetting;
use App\Services\BackupService;

class Kernel extends ConsoleKernel
{
    /**
     * Define the application's command schedule.
     */
    protected function schedule(Schedule $schedule): void
    {
        // 1. Auto-archive/cleanup logs older than 90 days
        $schedule->call(function () {
            ActivityLog::where('created_at', '<', now()->subDays(90))->delete();
        })->daily();

        // 2. Automated Backups based on Site Settings
        
        // Database Backup: Weekly at 2:00 AM (Configurable)
        $dbTime = SiteSetting::get('backup_time_db', '02:00');
        $schedule->call(function () {
            app(BackupService::class)->run('db');
        })->weekly()->at($dbTime);

        // File Uploads Backup: Weekly (Sundays)
        $schedule->call(function () {
            app(BackupService::class)->run('files');
        })->weeklyOn(0, '03:00');

        // Full System Backup: Monthly
        $schedule->call(function () {
            app(BackupService::class)->run('full');
        })->monthlyOn(1, '04:00');

        // 3. Backup Retention Cleanup (30 days)
        $schedule->call(function () {
            app(BackupService::class)->cleanup();
        })->daily();
    }

    /**
     * Register the commands for the application.
     */
    protected function commands(): void
    {
        $this->load(__DIR__.'/Commands');

        require base_path('routes/console.php');
    }
}
