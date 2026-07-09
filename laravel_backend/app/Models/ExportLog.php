<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class ExportLog extends Model
{
    use HasUuids;

    protected $fillable = [
        'user_id', 'filename', 'format', 'filters',
        'download_url', 'status'
    ];

    protected $casts = [
        'filters' => 'json'
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
