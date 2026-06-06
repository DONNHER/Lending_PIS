<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\SoftDeletes;
use App\Traits\Loggable;
use App\Traits\AdvancedDataControls;
use App\Traits\Versionable;
use Carbon\Carbon;

/**
 * Class User
 * 
 * Represents a system user with authentication, security (MFA, Lockout), 
 * and administrative attributes.
 * 
 * Features:
 * - UUID-based identification.
 * - Soft Deleting (Archiving).
 * - Multi-Factor Authentication (OTP).
 * - Automatic Account Lockout after failed attempts.
 * - Transaction Logging & Optimistic Locking.
 * 
 * @package App\Models
 */
class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable, HasUuids, Loggable, AdvancedDataControls, SoftDeletes, Versionable;

    // Status Constants
    const STATUS_ACTIVE = 'active';
    const STATUS_INACTIVE = 'inactive';
    const STATUS_SUSPENDED = 'suspended';

    // Role Constants
    const ROLE_ADMIN = 'admin';
    const ROLE_STAFF = 'staff';
    const ROLE_MEMBER = 'member';

    /**
     * The primary key associated with the table.
     */
    protected $keyType = 'string';

    /**
     * Indicates if the IDs are auto-incrementing.
     */
    public $incrementing = false;

    /**
     * Eloquent manages created_at and updated_at columns automatically.
     */
    public $timestamps = true;

    protected $fillable = [
        'username',
        'email',
        'password',
        'firstname',
        'lastname',
        'role',
        'status',
        'avatar_url',
        'failed_attempts',
        'locked_until',
        'mfa_code',
        'mfa_expires_at',
        'mfa_enabled',
        'version',
    ];

    protected $hidden = [
        'password',
        'remember_token',
        'mfa_code',
    ];

    protected $casts = [
        'locked_until' => 'datetime',
        'mfa_expires_at' => 'datetime',
        'mfa_enabled' => 'boolean',
        'version' => 'integer',
    ];

    /**
     * Check if the user is currently active.
     * 
     * @return bool
     */
    public function isActive(): bool
    {
        return $this->status === self::STATUS_ACTIVE;
    }

    /**
     * Check if the account is currently locked due to too many failed attempts.
     * 
     * @return bool
     */
    public function isLocked(): bool
    {
        if ($this->locked_until && $this->locked_until->isFuture()) {
            return true;
        }
        return false;
    }

    /**
     * Check if the user has administrator privileges.
     * 
     * @return bool
     */
    public function isAdmin(): bool
    {
        return $this->role === self::ROLE_ADMIN;
    }

    /**
     * Relationship: A user may be linked to a shareholder record.
     */
    public function shareholder()
    {
        return $this->hasOne(Shareholder::class, 'user_id');
    }
}
