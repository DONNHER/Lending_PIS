<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\SoftDeletes;
use App\Traits\Loggable;
use App\Traits\AdvancedDataControls;
use App\Traits\Versionable;

/**
 * Class Shareholder
 * 
 * Represents a member of the cooperative who holds share capital.
 * Tracks their personal details, total capital investment, and status.
 * 
 * @package App\Models
 */
class Shareholder extends Model
{
    use HasFactory, HasUuids, Loggable, AdvancedDataControls, SoftDeletes, Versionable;

    protected $fillable = [
        'user_id',
        'email',
        'firstname',
        'lastname',
        'share_capital',
        'status',
        'version',
    ];

    protected $casts = [
        'share_capital' => 'decimal:2',
        'version' => 'integer',
    ];

    /**
     * Relationship: Linked system user account.
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Relationship: All loans taken by this shareholder.
     */
    public function loans()
    {
        return $this->hasMany(Loan::class);
    }

    /**
     * Relationship: Financial transactions performed by this shareholder.
     */
    public function transactions()
    {
        return $this->hasMany(Transaction::class);
    }
}
