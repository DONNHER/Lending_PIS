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
Route::get('/health', function () {
    return response()->json(['status' => 'ok']);
});

Route::middleware('throttle:auth')->group(function () {
    Route::post('/login', [AuthController::class, 'login']);
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/forgot-password', [AuthController::class, 'forgotPassword']);
    Route::post('/reset-password', [AuthController::class, 'resetPassword']);
    Route::post('/verify-mfa', [AuthController::class, 'verifyMfa']);
    Route::post('/resend-mfa', [AuthController::class, 'resendMfa']);
});

// Protected Routes
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/user', function (Request $request) {
        // 🚀 Eager load shareholder to provide address and other details
        return $request->user()->load('shareholder');
    });
    
    // Support both PUT and POST for profile updates
    Route::match(['PUT', 'POST'], '/user/profile', [AuthController::class, 'updateProfile']);
    Route::match(['PUT', 'POST'], '/user/change-password', [AuthController::class, 'changePassword']);

    // 🚀 Loan Requests
    Route::get('/loan-requests/count', [LoanController::class, 'countRequests']);
    Route::post('/loan-requests/{id}/comaker-decision', [LoanController::class, 'setComakerDecision']);
    Route::post('/loan-requests/{id}/disburse', [LoanController::class, 'disburse']);
    Route::match(['PUT', 'POST'], '/loan-requests/{id}/status', [LoanController::class, 'updateRequestStatus']);
    Route::get('/loan-requests/{id}', [LoanController::class, 'showRequest']);
    Route::get('/loan-requests', [LoanController::class, 'indexRequests']);
    Route::post('/loan-requests', [LoanController::class, 'storeRequest']);

    // Dashboard
    Route::get('/dashboard/stats', [DashboardController::class, 'getStats']);

    // Admin Only Routes
    Route::middleware('admin')->group(function () {
        Route::prefix('backups')->group(function () {
            Route::get('/', [BackupController::class, 'listBackups']);
            Route::get('/settings', [BackupController::class, 'getSettings']);
            Route::put('/settings', [BackupController::class, 'updateSettings']);
            Route::post('/run', [BackupController::class, 'runManualBackup']);
        });

        Route::get('/admin/users/count', [UserController::class, 'count']);
        Route::apiResource('admin/users', UserController::class)->names([
            'index' => 'admin.users.index',
            'store' => 'admin.users.store',
            'show' => 'admin.users.show',
            'update' => 'admin.users.update',
            'destroy' => 'admin.users.destroy',
        ]);
        Route::get('/admin/users/{id}/login-history', [UserController::class, 'loginHistory']);
        
        // 🚀 Status & Address Updates
        Route::match(['PUT', 'POST'], '/admin/users/{id}/status', [UserController::class, 'updateStatus']);
        Route::match(['PUT', 'POST'], '/admin/users/{id}/address', [UserController::class, 'updateAddress']);

        Route::post('/activity-logs/cleanup', [ActivityLogController::class, 'cleanup']);
    });

    // Shareholders
    Route::get('/shareholders/count', [ShareholderController::class, 'count']);
    Route::get('/shareholders/user/{userId}', [ShareholderController::class, 'showByUserId']);
    Route::get('/shareholders/email/{email}', [ShareholderController::class, 'showByEmail']);
    Route::get('/shareholders', [ShareholderController::class, 'index']);
    Route::post('/shareholders', [ShareholderController::class, 'store']);
    Route::get('/shareholders/{id}', [ShareholderController::class, 'show']);
    Route::match(['PUT', 'POST'], '/shareholders/{id}', [ShareholderController::class, 'update']);
    Route::match(['PUT', 'POST'], '/shareholders/{id}/capital', [ShareholderController::class, 'updateCapital']);
    Route::delete('/shareholders/{id}', [ShareholderController::class, 'destroy']);

    // Activity Logs
    Route::get('/activity-logs/count', [ActivityLogController::class, 'count']);
    Route::apiResource('activity-logs', ActivityLogController::class)->only(['index', 'store', 'show']);

    // Lending & Interest Settings
    Route::get('/stats/total-disbursed', [LoanController::class, 'getTotalDisbursed']);
    Route::get('/stats/total-capital', [LoanController::class, 'getTotalCapital']);
    Route::get('/stats/active-loans-count', [LoanController::class, 'getActiveLoansCount']);
    Route::get('/lending/metrics', [LoanController::class, 'getMetrics']);
    
    // Interest Rate Routes
    Route::get('/settings/interest-rate', [LoanController::class, 'getInterestRate']);
    Route::post('/settings/interest-rate', [LoanController::class, 'updateInterestRate']);
    Route::get('/settings/interest-rate/history', [LoanController::class, 'getInterestRateHistory']);

    // Loans
    Route::get('/loans/by-request/{requestId}', [LoanController::class, 'showByRequest']);
    Route::get('/loans', [LoanController::class, 'index']);
    Route::post('/loans/{id}/payments', [LoanController::class, 'recordPayment']);
    Route::get('/loans/{id}', [LoanController::class, 'show']);
    Route::get('/shareholders/{shareholderId}/loans', [LoanController::class, 'getByShareholder']);

    // Consignees
    Route::get('/consignees/search', [ConsigneeController::class, 'search']);
    Route::apiResource('consignees', ConsigneeController::class);

    // Products
    Route::apiResource('products', ProductController::class);
    
    // Transactions
    Route::get('/transactions/count', [TransactionController::class, 'count']);
    Route::get('/transactions/shareholder/{shareholderId}', [TransactionController::class, 'getByShareholder']);
    Route::get('/transactions/reference/{referenceId}', [TransactionController::class, 'getByReference']);
    
    Route::apiResource('transactions', TransactionController::class)->only(['index', 'store']);

    // Notifications & Email
    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::match(['PUT', 'POST'], '/notifications/{id}/read', [NotificationController::class, 'markAsRead']);
    Route::post('/send-email', [NotificationController::class, 'sendEmail']);

    // File Upload
    Route::post('/upload', [FileUploadController::class, 'upload']);
});
