<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Web\AuthController;
use App\Http\Controllers\Web\DashboardController;

// Auth Routes
Route::get('/login', [AuthController::class, 'showLogin'])->name('login');
Route::post('/login', [AuthController::class, 'login']);
Route::post('/logout', [AuthController::class, 'logout'])->name('logout');

Route::get('/password/reset', [AuthController::class, 'showForgotPassword'])->name('password.request');

// Protected Routes
Route::middleware('auth')->group(function () {
    Route::get('/', [DashboardController::class, 'index'])->name('dashboard');
    Route::get('/dashboard', [DashboardController::class, 'index']);

    // Admin Only: Registration and User Management
    Route::middleware('admin')->group(function () {
        Route::get('/admin/register', [AuthController::class, 'showRegister'])->name('register');
        Route::post('/admin/register', [AuthController::class, 'register']);
        // Add other admin-only web routes here
    });
});

// Debug route to check if server is alive
Route::get('/debug-status', function () {
    return response()->json([
        'server' => 'OK',
        'php_version' => PHP_VERSION,
        'environment' => app()->environment(),
        'time' => now()->toDateTimeString(),
    ]);
});

Route::get('/debug-db', function () {
    try {
        \DB::connection()->getPdo();
        return response()->json(['database' => 'Connected successfully!']);
    } catch (\Exception $e) {
        return response()->json(['database' => 'Connection failed: ' . $e->getMessage()], 500);
    }
});

// Protected Routes
Route::middleware('auth')->group(function () {
    Route::get('/', [DashboardController::class, 'index'])->name('dashboard');
    Route::get('/dashboard', [DashboardController::class, 'index']);
});
