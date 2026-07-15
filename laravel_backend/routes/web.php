<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\File;

// This maps a clean URL /PIS/login to your internal Flutter route #/admin-login
Route::get('/PIS/login', function () {
    return file_get_contents(public_path('PIS/index.html'));
});

// Your existing catch-all
Route::get('/PIS/{any?}', function ($any = null) {
    $path = public_path('PIS/' . ($any ?? 'index.html'));
    if (File::exists($path) && !File::isDirectory($path)) {
        return response()->file($path);
    }
    return file_get_contents(public_path('PIS/index.html'));
})->where('any', '.*');