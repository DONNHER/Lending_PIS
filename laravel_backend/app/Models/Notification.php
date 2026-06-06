<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use App\Traits\Loggable;
use App\Traits\AdvancedDataControls;

class Notification extends Model
{
    use HasUuids, Loggable, AdvancedDataControls;

    protected $fillable = [
        'user_id',
        'shareholder_id',
        'comaker_id',
        'title',
        'content',
        'category',
        'type',
        'is_unread',
        'metadata',
    ];

    protected $casts = [
        'is_unread' => 'boolean',
        'metadata' => 'array',
    ];

    public $timestamps = false; // DB handles created_at
}
