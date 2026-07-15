<?php

namespace App\Exports;

use App\Models\ActivityLog;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithMapping;

class ActivityLogsExport implements FromCollection, WithHeadings, WithMapping
{
    public function collection()
    {
        return ActivityLog::with('user')->get();
    }

    public function headings(): array
    {
        return [
            'ID',
            'User',
            'Action',
            'Type',
            'Description',
            'IP Address',
            'Suspicious',
            'Created At',
        ];
    }

    public function map($log): array
    {
        return [
            $log->id,
            $log->user?->fullName ?? 'System',
            $log->action,
            strtoupper($log->log_type),
            $log->description,
            $log->ip_address,
            $log->is_suspicious ? 'YES' : 'NO',
            $log->created_at->toDateTimeString(),
        ];
    }
}
