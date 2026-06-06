<?php

namespace App\Services;

use App\Models\SiteSetting;
use App\Mail\BackupNotificationMail;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Log;
use ZipArchive;
use Exception;

/**
 * Class BackupService
 * 
 * Logic for automating system backups. 
 * Supports Database SQL dumps, File Upload archiving, and Full System snapshots.
 * 
 * @package App\Services
 */
class BackupService
{
    /**
     * Entry point to run a specific backup task.
     * 
     * @param string $type Type of backup: 'db', 'files', or 'full'.
     * @return array Success status and filename or error message.
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

            // Verify integrity: ensure file was actually written and has content
            if (!$this->verifyIntegrity($filename)) {
                throw new Exception("Backup integrity verification failed for $filename");
            }

            // Send Email Notification with attachment if status is success
            $this->notify('success', $type, $filename);

            // Cleanup: remove backups older than the retention period (default 30 days)
            $this->cleanup();

            return ['success' => true, 'filename' => $filename];
        } catch (Exception $e) {
            Log::error("Backup Failed ($type): " . $e->getMessage());
            $this->notify('failure', $type, null, $e->getMessage());
            return ['success' => false, 'error' => $e->getMessage()];
        }
    }

    /**
     * Create a SQL dump of the MySQL database.
     * Requires 'mysqldump' to be in the system PATH.
     */
    protected function backupDatabase()
    {
        $dbConfig = config('database.connections.mysql');
        $filename = 'backups/db_backup_' . date('Y-m-d_H-i-s') . '.sql';
        $fullPath = storage_path('app/' . $filename);

        if (!file_exists(storage_path('app/backups'))) {
            mkdir(storage_path('app/backups'), 0755, true);
        }

        $command = sprintf(
            'mysqldump --user=%s --password=%s --host=%s %s > %s',
            escapeshellarg($dbConfig['username']),
            escapeshellarg($dbConfig['password']),
            escapeshellarg($dbConfig['host']),
            escapeshellarg($dbConfig['database']),
            escapeshellarg($fullPath)
        );

        $output = [];
        $returnVar = 0;
        exec($command, $output, $returnVar);

        if ($returnVar !== 0) {
            throw new Exception("mysqldump failed with exit code $returnVar. Ensure it is installed and in the PATH.");
        }

        return $fullPath;
    }

    /**
     * Create a ZIP archive of user-uploaded files.
     */
    protected function backupFiles()
    {
        $filename = 'backups/files_backup_' . date('Y-m-d_H-i-s') . '.zip';
        $fullPath = storage_path('app/' . $filename);
        
        if (!file_exists(storage_path('app/backups'))) {
            mkdir(storage_path('app/backups'), 0755, true);
        }

        $sourcePath = storage_path('app/public'); 
        
        return $this->createZip($sourcePath, $fullPath);
    }

    /**
     * Create a ZIP archive of the entire project directory.
     */
    protected function backupFullSystem()
    {
        $filename = 'backups/full_system_backup_' . date('Y-m-d_H-i-s') . '.zip';
        $fullPath = storage_path('app/' . $filename);
        $sourcePath = base_path();

        if (!file_exists(storage_path('app/backups'))) {
            mkdir(storage_path('app/backups'), 0755, true);
        }
        
        return $this->createZip($sourcePath, $fullPath, true);
    }

    /**
     * Internal helper to create a recursive ZIP archive of a directory.
     */
    protected function createZip($source, $destination, $isFull = false)
    {
        $zip = new ZipArchive();
        if ($zip->open($destination, ZipArchive::CREATE | ZipArchive::OVERWRITE) !== TRUE) {
            throw new Exception("Cannot create zip file at $destination");
        }

        if (is_dir($source)) {
            $files = new \RecursiveIteratorIterator(
                new \RecursiveDirectoryIterator($source),
                \RecursiveIteratorIterator::LEAVES_ONLY
            );

            foreach ($files as $name => $file) {
                if (!$file->isDir()) {
                    $filePath = $file->getRealPath();
                    $relativePath = substr($filePath, strlen($source) + 1);

                    // Skip large/unnecessary folders for system backups
                    if ($isFull) {
                        if (str_contains($relativePath, 'vendor') || 
                            str_contains($relativePath, 'node_modules') || 
                            str_contains($relativePath, 'storage/app/backups') ||
                            str_contains($relativePath, '.git')) {
                            continue;
                        }
                    }

                    $zip->addFile($filePath, $relativePath);
                }
            }
        }

        $zip->close();
        return $destination;
    }

    /**
     * Basic integrity check.
     */
    protected function verifyIntegrity($filePath)
    {
        return file_exists($filePath) && filesize($filePath) > 0;
    }

    /**
     * Send backup status notification to the configured administrator email.
     */
    protected function notify($status, $type, $filePath = null, $error = null)
    {
        $adminEmail = SiteSetting::get('backup_email', config('mail.from.address'));
        
        try {
            Mail::to($adminEmail)->send(new BackupNotificationMail($status, $type, $filePath, $error));
        } catch (Exception $e) {
            Log::error("Failed to send backup notification email: " . $e->getMessage());
        }
    }

    /**
     * Enforce retention policy by deleting files older than the configured threshold.
     */
    public function cleanup()
    {
        $retentionDays = SiteSetting::get('backup_retention_days', 30);
        $files = Storage::disk('local')->files('backups');
        
        foreach ($files as $file) {
            $lastModified = Storage::disk('local')->lastModified($file);
            if (now()->timestamp - $lastModified > ($retentionDays * 24 * 60 * 60)) {
                Storage::disk('local')->delete($file);
            }
        }
    }
}
