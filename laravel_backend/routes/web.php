use Illuminate\Support\Facades\File;

Route::get('/PIS/{any?}', function ($any = null) {
    $path = public_path('PIS/' . ($any ?? 'index.html'));

    // 1. If it's a real file (main.dart.js, favicon.png, etc.), serve it!
    if (File::exists($path) && !File::isDirectory($path)) {
        return response()->file($path);
    }

    // 2. If it's NOT a file (e.g., /PIS/login), serve index.html
    // This allows Flutter's internal router to take over
    return file_get_contents(public_path('PIS/index.html'));
})->where('any', '.*');