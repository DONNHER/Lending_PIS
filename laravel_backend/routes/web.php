<?php

use Illuminate\Support\Facades\File;

Route::get('/PIS/{any?}', function ($any = null) {
    // 1. Define the path to your assets
    $path = public_path('PIS/' . ($any ?? 'index.html'));

    // 2. If it's a real file (like main.dart.js), serve it
    if (File::exists($path) && !File::isDirectory($path)) {
        return response()->file($path);
    }

    // 3. Otherwise, return index.html for Flutter routing
    return file_get_contents(public_path('PIS/index.html'));
})->where('any', '.*');