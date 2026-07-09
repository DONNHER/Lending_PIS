<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class ImportLog extends Model
{
    use HasUuids;

    protected $fillable = [
        'user_id', 'filename', 'module', 'total_rows',
        'processed_rows', 'failed_rows', 'errors', 'status'
    ];

    protected $casts = [
        'errors' => 'json'
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
