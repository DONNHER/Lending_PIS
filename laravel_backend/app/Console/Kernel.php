<?php

namespace App\Console;

use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Foundation\Console\Kernel as ConsoleKernel;
use App\Models\ActivityLog;
use App\Models\SiteSetting;
use App\Models\Loan;
use App\Models\User;
use App\Services\BackupService;
use App\Services\NotificationService;

class Kernel extends ConsoleKernel
{
    /**
     * Define the application's command schedule.
     */
    protected function schedule(Schedule $schedule): void
    {
        // 🚀 Automated Backup System (Spatie)
        $schedule->command('backup:run')->dailyAt('02:00')
            ->withoutOverlapping()
            ->onFailure(fn() => \Log::error('Daily backup failed.'))
            ->onSuccess(fn() => \Log::info('Daily backup completed.'));

        $schedule->command('backup:clean')->dailyAt('03:00')
            ->withoutOverlapping();

        // 🚀 Weekly Database Backup (Requirement: Weekly at 2:00 AM)
        $schedule->command('backup:weekly')->mondays()->at('02:00')
            ->withoutOverlapping()
            ->onFailure(fn() => \Log::error('Weekly automated backup failed.'))
            ->onSuccess(fn() => \Log::info('Weekly automated backup completed.'));

        // 🚀 Maintenance Tasks
        $schedule->command('session:table')->daily(); // Placeholder for session cleanup if using DB

        $schedule->call(function () {
            // notification:prune Weekly Delete old notification records > 90 days
            \App\Models\Notification::where('created_at', '<', now()->subDays(90))->delete();
        })->weekly();

        $schedule->call(function () {
            // audit:archive Monthly Archive audit logs > 1 year old
            // In a real app, this might move to a separate 'audit_archives' table or S3
            \App\Models\ActivityLog::where('created_at', '<', now()->subYear())->delete();
        })->monthly();

        // Daily Sales/Transaction Report at 06:00
        $schedule->call(function () {
            $admins = User::where('role', 'admin')->get();
            foreach ($admins as $admin) {
                NotificationService::send(
                    $admin->id,
                    'Daily Sales Report',
                    'The daily transaction summary for ' . now()->subDay()->format('M d, Y') . ' has been generated.',
                    'system',
                    'info'
                );
            }
        })->dailyAt('06:00');

        // Loan Payment Reminders (Existing logic)
        $schedule->call(function () {
            $upcomingLoans = Loan::where('status', 'active')
                ->where('next_repayment_date', '<=', now()->addDays(3))
                ->where('next_repayment_date', '>', now())
                ->with('shareholder.user')
                ->get();

            foreach ($upcomingLoans as $loan) {
                if ($loan->shareholder && $loan->shareholder->user) {
                    NotificationService::send(
                        $loan->shareholder->user->id,
                        'Loan Payment Reminder',
                        "Your loan payment of ₱" . number_format($loan->monthly_amortization, 2) . " is due on " . $loan->next_repayment_date->format('M d, Y') . ".",
                        'reminder',
                        'info'
                    );
                }
            }
        })->dailyAt('08:00');
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
