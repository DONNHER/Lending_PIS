<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Web\AuthController;
use App\Http\Controllers\Web\DashboardController;
use App\Http\Controllers\Web\ShareholderController;
use App\Http\Controllers\Web\LoanController;
use App\Http\Controllers\Web\LoanRequestController;
use App\Http\Controllers\Web\TransactionController;
use App\Http\Controllers\Web\SettingsController;
use App\Http\Controllers\Web\ActivityLogController;
use App\Http\Controllers\Web\ProfileController;
use App\Http\Controllers\Web\NotificationController;
use App\Http\Controllers\Web\UserController;
use App\Http\Controllers\Web\BackupController;

// Auth Routes
Route::get('/login', [AuthController::class, 'showLogin'])->name('login');
Route::post('/login', [AuthController::class, 'login']);
Route::get('/login/verify', [AuthController::class, 'showMfa'])->name('login.mfa');
Route::post('/login/verify', [AuthController::class, 'verifyMfa'])->name('login.mfa.verify');
Route::post('/login/resend', [AuthController::class, 'resendMfa'])->name('login.mfa.resend');
Route::post('/logout', [AuthController::class, 'logout'])->name('logout');

Route::get('/password/reset', [AuthController::class, 'showForgotPassword'])->name('password.request');
Route::post('/password/email', [AuthController::class, 'sendResetLinkEmail'])->name('password.email');

// Protected Routes
Route::middleware('auth')->group(function () {
    Route::get('/', [DashboardController::class, 'index'])->name('dashboard');
    Route::get('/dashboard', [DashboardController::class, 'index']);

    // Shareholder Specific
    Route::middleware('role:member')->group(function () {
        Route::get('/apply-loan', [ShareholderPortalController::class, 'showApplicationForm'])->name('shareholder.loan.apply');
        Route::post('/apply-loan', [ShareholderPortalController::class, 'storeApplication'])->name('shareholder.loan.store');
        Route::get('/signatures', [ShareholderPortalController::class, 'comakerRequests'])->name('shareholder.loan.comaker.requests');
        Route::post('/signatures/{loanRequest}', [ShareholderPortalController::class, 'signComaker'])->name('shareholder.loan.comaker.sign');
    });

    // Profile Settings
    Route::get('/profile', [ProfileController::class, 'show'])->name('profile.show');
    Route::put('/profile', [ProfileController::class, 'update'])->name('profile.update');
    Route::put('/profile/password', [ProfileController::class, 'updatePassword'])->name('profile.password');
    Route::patch('/profile/mfa', [ProfileController::class, 'toggleMfa'])->name('profile.mfa.toggle');

    // Notifications
    Route::get('/notifications', [NotificationController::class, 'index'])->name('notifications.index');
    Route::patch('/notifications/{notification}/read', [NotificationController::class, 'markAsRead'])->name('notifications.read');
    Route::post('/notifications/read-all', [NotificationController::class, 'markAllAsRead'])->name('notifications.read-all');

    // Admin Only: Management
    Route::middleware('admin')->group(function () {
        Route::get('/admin/register', [AuthController::class, 'showRegister'])->name('register');
        Route::post('/admin/register', [AuthController::class, 'register']);

        // Users
        Route::get('/admin/users', [UserController::class, 'index'])->name('admin.users.index');
        Route::patch('/admin/users/{user}/status', [UserController::class, 'updateStatus'])->name('admin.users.status');

        // Shareholders
        Route::get('/admin/shareholders', [ShareholderController::class, 'index'])->name('admin.shareholders.index');
        Route::get('/admin/shareholders/create', [ShareholderController::class, 'create'])->name('admin.shareholders.create');
        Route::get('/admin/shareholders/{shareholder}', [ShareholderController::class, 'show'])->name('admin.shareholders.show');
        Route::get('/admin/shareholders/{shareholder}/add-capital', [ShareholderController::class, 'addCapital'])->name('admin.shareholders.add-capital');
        Route::post('/admin/shareholders/{shareholder}/add-capital', [ShareholderController::class, 'storeCapital'])->name('admin.shareholders.add-capital.store');

        // Loans & Requests
        Route::get('/admin/loan-requests', [LoanRequestController::class, 'index'])->name('admin.loan-requests.index');
        Route::get('/admin/loan-requests/create', [LoanRequestController::class, 'create'])->name('admin.loan-requests.create');
        Route::post('/admin/loan-requests', [LoanRequestController::class, 'store'])->name('admin.loan-requests.store');
        Route::get('/admin/loan-requests/{loanRequest}', [LoanRequestController::class, 'show'])->name('admin.loan-requests.show');
        Route::post('/admin/loan-requests/{loanRequest}/status', [LoanRequestController::class, 'updateStatus'])->name('admin.loan-requests.update');

        Route::get('/admin/loans', [LoanController::class, 'index'])->name('admin.loans.index');
        Route::get('/admin/loans/{loan}', [LoanController::class, 'show'])->name('admin.loans.show');
        Route::get('/admin/loans/{loan}/payment', [LoanController::class, 'payment'])->name('admin.loans.payment');
        Route::post('/admin/loans/{loan}/payment', [LoanController::class, 'storePayment'])->name('admin.loans.payment.store');

        // Transactions
        Route::get('/admin/transactions', [TransactionController::class, 'index'])->name('admin.transactions.index');

        // Activity Logs
        Route::get('/admin/activity-logs', [ActivityLogController::class, 'index'])->name('admin.activity-logs.index');
        Route::get('/admin/activity-logs/{activityLog}', [ActivityLogController::class, 'show'])->name('admin.activity-logs.show');

        // Backups
        Route::get('/admin/backups', [BackupController::class, 'index'])->name('admin.backups.index');
        Route::post('/admin/backups/run', [BackupController::class, 'run'])->name('admin.backups.run');

        // Settings
        Route::get('/admin/settings', [SettingsController::class, 'index'])->name('admin.settings.index');
        Route::post('/admin/settings/interest', [SettingsController::class, 'updateInterest'])->name('admin.settings.interest');
    });
});
