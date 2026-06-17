<?php

namespace App\Services;

use App\Models\SiteSetting;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Log;
use ZipArchive;
use Exception;

/**
 * Class BackupService
 * 
 * Logic for automating system backups. 
 * Supports Database SQL dumps, File Upload archiving, and Full System snapshots.
 */
class BackupService
{
    protected $resend;

    public function __construct(ResendService $resend)
    {
        $this->resend = $resend;
    }

    /**
     * Entry point to run a specific backup task.
     */
    public function run($type = 'db')
    {
        $filename = "";
        try {
            switch ($type) {
                case 'db':
                    $filename = $this->backupDatabase();
                    break;
                case 'files':
                    $filename = $this->backupFiles();
                    break;
                case 'full':
                    $filename = $this->backupFullSystem();
                    break;
                default:
                    throw new Exception("Invalid backup type: $type");
            }

            if (!$this->verifyIntegrity($filename)) {
                throw new Exception("Backup integrity verification failed for $filename");
            }

            $this->notify('success', $type, $filename);
            $this->cleanup();

            return ['success' => true, 'filename' => $filename];
        } catch (Exception $e) {
            Log::error("Backup Failed ($type): " . $e->getMessage());
            $this->notify('failure', $type, null, $e->getMessage());
            return ['success' => false, 'error' => $e->getMessage()];
        }
    }

    protected function backupDatabase()
    {
        // ... (implementation same as before, but ensure it points to correct DB)
        $dbConfig = config('database.connections.pgsql'); // Changed to pgsql as per your .env
        $filename = 'backups/db_backup_' . date('Y-m-d_H-i-s') . '.sql';
        $fullPath = storage_path('app/' . $filename);

        if (!file_exists(storage_path('app/backups'))) {
            mkdir(storage_path('app/backups'), 0755, true);
        }

        // Note: For pgsql, we'd use pg_dump
        $command = sprintf(
            'PGPASSWORD=%s pg_dump -h %s -p %s -U %s %s > %s',
            escapeshellarg($dbConfig['password']),
            escapeshellarg($dbConfig['host']),
            escapeshellarg($dbConfig['port']),
            escapeshellarg($dbConfig['username']),
            escapeshellarg($dbConfig['database']),
            escapeshellarg($fullPath)
        );

        exec($command, $output, $returnVar);
        if ($returnVar !== 0) throw new Exception("Database dump failed");

        return $fullPath;
    }

    protected function backupFiles()
    {
        $filename = 'backups/files_backup_' . date('Y-m-d_H-i-s') . '.zip';
        $fullPath = storage_path('app/' . $filename);
        if (!file_exists(storage_path('app/backups'))) mkdir(storage_path('app/backups'), 0755, true);
        return $this->createZip(storage_path('app/public'), $fullPath);
    }

    protected function backupFullSystem()
    {
        $filename = 'backups/full_system_backup_' . date('Y-m-d_H-i-s') . '.zip';
        $fullPath = storage_path('app/' . $filename);
        if (!file_exists(storage_path('app/backups'))) mkdir(storage_path('app/backups'), 0755, true);
        return $this->createZip(base_path(), $fullPath, true);
    }

    protected function createZip($source, $destination, $isFull = false)
    {
        $zip = new ZipArchive();
        if ($zip->open($destination, ZipArchive::CREATE | ZipArchive::OVERWRITE) !== TRUE) {
            throw new Exception("Cannot create zip file");
        }

        if (is_dir($source)) {
            $files = new \RecursiveIteratorIterator(new \RecursiveDirectoryIterator($source), \RecursiveIteratorIterator::LEAVES_ONLY);
            foreach ($files as $name => $file) {
                if (!$file->isDir()) {
                    $filePath = $file->getRealPath();
                    $relativePath = substr($filePath, strlen($source) + 1);
                    if ($isFull && (str_contains($relativePath, 'vendor') || str_contains($relativePath, 'storage/app/backups'))) continue;
                    $zip->addFile($filePath, $relativePath);
                }
            }
        }
        $zip->close();
        return $destination;
    }

    protected function verifyIntegrity($filePath)
    {
        return file_exists($filePath) && filesize($filePath) > 0;
    }

    protected function notify($status, $type, $filePath = null, $error = null)
    {
        $adminEmail = env('MAIL_FROM_ADDRESS', 'onboarding@resend.dev');
        $subject = "Backup " . ucfirst($status) . ": " . ucfirst($type);
        
        $html = "<h1>Backup Status: " . ucfirst($status) . "</h1>";
        $html .= "<p>Type: " . ucfirst($type) . "</p>";
        if ($error) $html .= "<p style='color:red;'>Error: $error</p>";
        $html .= "<p>Date: " . date('Y-m-d H:i:s') . "</p>";

        $attachments = [];
        if ($status === 'success' && $filePath && file_exists($filePath) && filesize($filePath) < 10 * 1024 * 1024) {
            $attachments[] = [
                'filename' => basename($filePath),
                'path' => $filePath,
            ];
        }

        $this->resend->sendEmail($adminEmail, $subject, $html, null, $attachments);
    }

    public function cleanup()
    {
        $retentionDays = 30;
        $files = Storage::disk('local')->files('backups');
        foreach ($files as $file) {
            $lastModified = Storage::disk('local')->lastModified($file);
            if (now()->timestamp - $lastModified > ($retentionDays * 24 * 60 * 60)) {
                Storage::disk('local')->delete($file);
            }
        }
    }
}
