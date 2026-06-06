<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

/**
 * Class ActivityLog
 * 
 * Central audit trail for the application. 
 * Records authentication events, financial transactions, data changes, and errors.
 * 
 * @package App\Models
 */
class ActivityLog extends Model
{
    use HasUuids;

    // Log Type Constants
    const TYPE_AUTH = 'auth';
    const TYPE_TRANSACTION = 'transaction';
    const TYPE_ERROR = 'error';
    const TYPE_ACCESS = 'access';
    const TYPE_GENERAL = 'general';

    protected $fillable = [
        'user_id',
        'shareholder_id',
        'action',
        'log_type',
        'description',
        'old_values',
        'new_values',
        'ip_address',
        'device_info',
        'is_suspicious',
    ];

    protected $casts = [
        'old_values' => 'array',
        'new_values' => 'array',
        'is_suspicious' => 'boolean',
        'created_at' => 'datetime',
    ];

    /**
     * @var bool Disables standard timestamps. 'created_at' is handled by DB defaults.
     */
    public $timestamps = false;

    /**
     * Relationship: The system user who performed the action.
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
