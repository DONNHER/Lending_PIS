<?php

use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
*/

// API health check
Route::get('/', function () {
    return response()->json([
        'status' => 'online',
        'message' => 'Lending PIS Backend is Online',
        'version' => '1.0.0',
    ]);
});

// --- FLUTTER FRONTEND INTEGRATION ---

// This handles /Dashboard (exactly) and /Dashboard/anything-else
Route::get('/PIS/{any?}', function ($any = null) {
    $path = public_path('PIS/index.html');

    if (!file_exists($path)) {
        return "Error: index.html not found at $path";
    }

    return file_get_contents($path);
})->where('any', '.*');