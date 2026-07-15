<?php

namespace App\Exports;

use Maatwebsite\Excel\Concerns\FromArray;
use Maatwebsite\Excel\Concerns\WithHeadings;

class ErrorsExport implements FromArray, WithHeadings
{
    protected $errors;

    public function __construct(array $errors)
    {
        $this->errors = $errors;
    }

    public function array(): array
    {
        return array_map(function($error) {
            return [
                'Row' => $error['row'],
                'Errors' => implode(', ', $error['messages']),
                'Data' => json_encode($error['data'])
            ];
        }, $this->errors);
    }

    public function headings(): array
    {
        return [
            'Row Number',
            'Error Messages',
            'Original Data'
        ];
    }
}
