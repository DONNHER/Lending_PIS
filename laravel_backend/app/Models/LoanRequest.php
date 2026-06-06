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
 * Class LoanRequest
 * 
 * Represents an initial application for a loan by a shareholder.
 * It undergoes a review process where it can be approved, rejected, or pending.
 * 
 * @package App\Models
 */
class LoanRequest extends Model
{
    use HasFactory, HasUuids, Loggable, AdvancedDataControls, SoftDeletes, Versionable;

    protected $fillable = [
        'shareholder_id',
        'amount',
        'purpose',
        'status',
        'reviewed_by',
        'reviewed_at',
        'rejection_reason',
        'version',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'reviewed_at' => 'datetime',
        'version' => 'integer',
    ];

    /**
     * Relationship: The shareholder who is requesting the loan.
     */
    public function shareholder()
    {
        return $this->belongsTo(Shareholder::class);
    }
}
