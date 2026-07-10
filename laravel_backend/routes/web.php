<?php

use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| This backend is primarily used as an API for the Flutter application.
| Web routes are disabled to prevent 500 errors due to missing controllers.
|
*/

Route::get('/', function () {
    return response()->json([
        'status' => 'online',
        'message' => 'Lending PIS Backend is Online',
        'version' => '1.0.0',
        'documentation' => '/api/health'
    ]);
});

// Redirect common web paths to the landing page to prevent 500 errors
Route::any('/login', function() { return redirect('/'); });
Route::any('/dashboard', function() { return redirect('/'); });
Route::any('/admin/{any?}', function() { return redirect('/'); })->where('any', '.*');
