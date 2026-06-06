<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ShareholderController;
use App\Http\Controllers\Api\LoanController;
use App\Http\Controllers\Api\ConsigneeController;
use App\Http\Controllers\Api\ActivityLogController;
use App\Http\Controllers\Api\FileUploadController;
use App\Http\Controllers\Api\TransactionController;
use App\Http\Controllers\Api\ProductController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\BackupController;
use App\Http\Controllers\Api\UserController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// Public Routes
Route::post('/login', [AuthController::class, 'login']);
Route::post('/register', [AuthController::class, 'register']);
Route::post('/forgot-password', [AuthController::class, 'forgotPassword']);
Route::post('/reset-password', [AuthController::class, 'resetPassword']);
Route::post('/verify-mfa', [AuthController::class, 'verifyMfa']);

// Protected Routes
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/user', function (Request $request) {
        return $request->user();
    });

    // Dashboard
    Route::get('/dashboard/stats', [DashboardController::class, 'getStats']);

    // Admin Only Routes
    Route::middleware('admin')->group(function () {
        // Backups
        Route::prefix('backups')->group(function () {
            Route::get('/', [BackupController::class, 'listBackups']);
            Route::get('/settings', [BackupController::class, 'getSettings']);
            Route::put('/settings', [BackupController::class, 'updateSettings']);
            Route::post('/run', [BackupController::class, 'runManualBackup']);
        });

        // Advanced User Management
        Route::prefix('admin/users')->group(function () {
            Route::get('/', [UserController::class, 'index']);
            Route::post('/', [UserController::class, 'store']);
            Route::get('/{id}', [UserController::class, 'show']);
            Route::put('/{id}', [UserController::class, 'update']);
            Route::delete('/{id}', [UserController::class, 'destroy']);
            Route::post('/bulk-action', [UserController::class, 'bulkAction']);
            Route::post('/import', [UserController::class, 'import']);
            Route::post('/{id}/impersonate', [UserController::class, 'impersonate']);
            Route::post('/{id}/force-logout', [UserController::class, 'forceLogout']);
            Route::get('/{id}/login-history', [UserController::class, 'loginHistory']);
            Route::get('/{id}/analytics', [UserController::class, 'analytics']);
        });
        
        // Activity Logs Maintenance
        Route::post('/activity-logs/cleanup', [ActivityLogController::class, 'cleanup']);
        Route::delete('/activity-logs/{id}', [ActivityLogController::class, 'destroy']);
    });

    // Profile Management
    Route::put('/user/profile', [AuthController::class, 'updateProfile']);
    Route::put('/user/change-password', [AuthController::class, 'changePassword']);

    // Activity Logs (Viewing)
    Route::get('/activity-logs/count', [ActivityLogController::class, 'count']);
    Route::get('/activity-logs/export', [ActivityLogController::class, 'export']);
    Route::get('/activity-logs', [ActivityLogController::class, 'index']);
    Route::post('/activity-logs', [ActivityLogController::class, 'store']);
    Route::get('/activity-logs/{id}', [ActivityLogController::class, 'show']);

    // Shareholders
    Route::get('/shareholders/count', [ShareholderController::class, 'count']);
    Route::get('/shareholders/user/{userId}', [ShareholderController::class, 'showByUserId']);
    Route::get('/shareholders/email/{email}', [ShareholderController::class, 'showByEmail']);
    Route::get('/shareholders', [ShareholderController::class, 'index']);
    Route::post('/shareholders', [ShareholderController::class, 'store']);
    Route::put('/shareholders/{id}/capital', [ShareholderController::class, 'updateCapital']);
    Route::delete('/shareholders/{id}', [ShareholderController::class, 'destroy']);

    // Lending Stats & Settings
    Route::get('/stats/total-disbursed', [LoanController::class, 'getTotalDisbursed']);
    Route::get('/stats/total-capital', [LoanController::class, 'getTotalCapital']);
    Route::get('/stats/active-loans-count', [LoanController::class, 'getActiveLoansCount']);
    Route::get('/settings/interest-rate', [LoanController::class, 'getInterestRate']);
    Route::get('/settings/interest-rate/history', [LoanController::class, 'getInterestRateHistory']);
    Route::get('/lending/metrics', [LoanController::class, 'getMetrics']);

    // Loan Requests
    Route::get('/loan-requests/count', [LoanController::class, 'countRequests']);
    Route::get('/loan-requests', [LoanController::class, 'indexRequests']);
    Route::post('/loan-requests', [LoanController::class, 'storeRequest']);
    Route::put('/loan-requests/{id}/status', [LoanController::class, 'updateRequestStatus']);

    // Loans
    Route::get('/loans', [LoanController::class, 'index']);
    Route::get('/loans/{id}', [LoanController::class, 'show']);
    Route::get('/shareholders/{shareholderId}/loans', [LoanController::class, 'getByShareholder']);

    // Consignees
    Route::get('/consignees/search', [ConsigneeController::class, 'search']);
    Route::get('/consignees', [ConsigneeController::class, 'index']);
    Route::post('/consignees', [ConsigneeController::class, 'store']);
    Route::get('/consignees/{id}', [ConsigneeController::class, 'show']);
    Route::put('/consignees/{id}', [ConsigneeController::class, 'update']);
    Route::delete('/consignees/{id}', [ConsigneeController::class, 'destroy']);

    // Products & Inventory
    Route::get('/products', [ProductController::class, 'index']);
    Route::post('/products', [ProductController::class, 'store']);
    Route::get('/products/{id}', [ProductController::class, 'show']);
    Route::put('/products/{id}', [ProductController::class, 'update']);
    Route::delete('/products/{id}', [ProductController::class, 'destroy']);
    Route::get('/products/{id}/batches', [ProductController::class, 'getBatches']);
    
    // Transactions
    Route::get('/transactions/count', [TransactionController::class, 'count']);
    Route::get('/transactions', [TransactionController::class, 'index']);
    Route::get('/transactions/shareholder/{shareholderId}', [TransactionController::class, 'getByShareholder']);
    Route::post('/transactions', [TransactionController::class, 'store']);

    // Notifications
    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::put('/notifications/{id}/read', [NotificationController::class, 'markAsRead']);
    Route::put('/notifications/read-all', [NotificationController::class, 'markAllAsRead']);

    // File Upload
    Route::post('/upload', [FileUploadController::class, 'upload']);
});
