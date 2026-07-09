<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Services\BackupService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Carbon\Carbon;

class BackupController extends Controller
{
    protected $backupService;

    public function __construct(BackupService $backupService)
    {
        $this->backupService = $backupService;
    }

    public function index()
    {
        $files = Storage::disk('local')->files('backups');
        $backups = collect($files)->map(function ($file) {
            return (object) [
                'name' => basename($file),
                'size' => round(Storage::disk('local')->size($file) / 1024 / 1024, 2) . ' MB',
                'created_at' => Carbon::createFromTimestamp(Storage::disk('local')->lastModified($file)),
                'path' => $file
            ];
        })->sortByDesc('created_at');

        return view('admin.backups.index', compact('backups'));
    }

    public function run(Request $request)
    {
        $type = $request->get('type', 'db');
        $result = $this->backupService->run($type);

        if ($result['success']) {
            return back()->with('success', ucfirst($type) . ' backup completed and verified: ' . basename($result['filename']));
        }

        return back()->with('error', 'Backup failed: ' . $result['error']);
    }

    public function download($filename)
    {
        $path = 'backups/' . $filename;
        if (Storage::disk('local')->exists($path)) {
            return Storage::disk('local')->download($path);
        }
        return back()->with('error', 'File not found.');
    }
}
