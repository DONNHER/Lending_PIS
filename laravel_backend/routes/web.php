<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Web\AuthController;
use App\Http\Controllers\Web\DashboardController;

// Auth Routes
Route::get('/login', [AuthController::class, 'showLogin'])->name('login');
Route::post('/login', [AuthController::class, 'login']);
Route::post('/logout', [AuthController::class, 'logout'])->name('logout');

Route::get('/register', [AuthController::class, 'showRegister'])->name('register');
Route::post('/register', [AuthController::class, 'register']);

Route::get('/password/reset', [AuthController::class, 'showForgotPassword'])->name('password.request');

// Debug route to check if server is alive and DB connection
Route::get('/debug-status', function () {
    $results = [
        'server' => 'OK',
        'php_version' => PHP_VERSION,
        'environment' => app()->environment(),
        'database' => 'Testing...',
    ];

    try {
        \DB::connection()->getPdo();
        $results['database'] = 'Connected successfully!';
    } catch (\Exception $e) {
        $results['database'] = 'Connection failed: ' . $e->getMessage();
    }

    return response()->json($results);
});

// Protected Routes
Route::middleware('auth')->group(function () {
    Route::get('/', [DashboardController::class, 'index'])->name('dashboard');
    Route::get('/dashboard', [DashboardController::class, 'index']);
});
