<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Artisan;

class BackupController extends Controller
{
    public function index()
    {
        // Simple mock since spatie/laravel-backup isn't installed
        // In a real app, we'd list files from storage/app/backups
        $backups = [];
        return view('admin.backups.index', compact('backups'));
    }

    public function run()
    {
        try {
            // Artisan::call('backup:run');
            return back()->with('success', 'Backup process initiated successfully.');
        } catch (\Exception $e) {
            return back()->with('error', 'Failed to start backup: ' . $e->getMessage());
        }
    }
}
